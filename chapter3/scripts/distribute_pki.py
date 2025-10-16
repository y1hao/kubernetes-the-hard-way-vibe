#!/usr/bin/env python3
"""Distribute Chapter 3 PKI assets from the bastion host to target nodes.

Reads `chapter3/pki/manifest.yaml` and `chapter2/inventory.yaml` to copy the
required certificates, keys, and encryption config to each node. Designed to run
from the bastion after the repository has been copied there.
"""

import argparse
import os
import subprocess
import sys
import tempfile
import uuid
from dataclasses import dataclass
from pathlib import Path

try:
    import yaml  # type: ignore
except ImportError as exc:  # pragma: no cover
    print("[ERROR] PyYAML is required: pip install pyyaml", file=sys.stderr)
    raise SystemExit(1) from exc


@dataclass
class Task:
    node: str
    destination: Path
    source: Path
    mode: str
    is_local: bool


def load_yaml(path: Path):
    with path.open() as fh:
        return yaml.safe_load(fh)


def build_node_map(inventory: dict) -> dict:
    nodes = {}
    for group in ("control_planes", "workers"):
        for entry in inventory.get(group, []) or []:
            nodes[entry["name"]] = entry["private_ip"]
    return nodes


def is_private_key(path: Path) -> bool:
    return path.name.endswith("-key.pem") or path.suffix == ".key"


def determine_mode(source: Path, explicit_sensitive: bool = False) -> str:
    if explicit_sensitive or is_private_key(source):
        return "600"
    return "644"


def task_from_entry(manifest_root: Path, entry: dict, node: str, base_dest: Path, is_sensitive: bool = False):
    tasks = []

    if "cert" in entry:
        cert_source = (manifest_root / entry["cert"]).resolve()
        tasks.append(
            Task(
                node=node,
                destination=base_dest,
                source=cert_source,
                mode=determine_mode(cert_source, explicit_sensitive=False),
                is_local=(node == "bastion"),
            )
        )

    if "key" in entry:
        key_source = (manifest_root / entry["key"]).resolve()
        dest_dir = base_dest.parent
        key_dest = dest_dir / key_source.name
        tasks.append(
            Task(
                node=node,
                destination=key_dest,
                source=key_source,
                mode=determine_mode(key_source, explicit_sensitive=True),
                is_local=(node == "bastion"),
            )
        )

    if "file" in entry:
        file_source = (manifest_root / entry["file"]).resolve()
        tasks.append(
            Task(
                node=node,
                destination=base_dest,
                source=file_source,
                mode=determine_mode(file_source, explicit_sensitive=True if is_sensitive else False),
                is_local=(node == "bastion"),
            )
        )

    return tasks


def collect_tasks(manifest_path: Path) -> list:
    manifest = load_yaml(manifest_path)
    entries = manifest.get("entries", [])
    manifest_root = manifest_path.parent
    tasks = []

    for entry in entries:
        destination_info = entry.get("destination", {})
        base_path = destination_info.get("path")
        if not base_path:
            continue
        base_dest = Path(base_path)

        sensitive = entry.get("sensitive", False)

        if "perNode" in entry:
            for node, node_entry in entry["perNode"].items():
                node_dest_path = Path(node_entry.get("destination", {}).get("path", base_dest))
                tasks.extend(task_from_entry(manifest_root, node_entry, node, node_dest_path, is_sensitive=sensitive))
        else:
            nodes = destination_info.get("nodes", [])
            for node in nodes:
                tasks.extend(task_from_entry(manifest_root, entry, node, base_dest, is_sensitive=sensitive))

    return tasks


def run_local(task: Task, dry_run: bool):
    dest_dir = task.destination.parent
    cmd = ["sudo", "mkdir", "-p", str(dest_dir)]
    print(f"[LOCAL] {' '.join(cmd)}")
    if not dry_run:
        subprocess.run(cmd, check=True)

    install_cmd = [
        "sudo",
        "install",
        "-o",
        "root",
        "-g",
        "root",
        "-m",
        task.mode,
        str(task.source),
        str(task.destination),
    ]
    print(f"[LOCAL] {' '.join(install_cmd)}")
    if not dry_run:
        subprocess.run(install_cmd, check=True)


def scp_to_remote(task: Task, node: str, user: str, host: str, key_path: Path, dry_run: bool):
    remote_tmp = f"/tmp/kthw-pki-{uuid.uuid4().hex}-{task.source.name}"
    scp_cmd = [
        "scp",
        "-i",
        str(key_path),
        "-o",
        "StrictHostKeyChecking=no",
        "-o",
        "UserKnownHostsFile=/dev/null",
        str(task.source),
        f"{user}@{host}:{remote_tmp}",
    ]
    print(f"[{node}] {' '.join(scp_cmd)}")
    if not dry_run:
        subprocess.run(scp_cmd, check=True)

    remote_dir = task.destination.parent
    remote_commands = [
        f"sudo mkdir -p {remote_dir}",
        f"sudo mv {remote_tmp} {task.destination}",
        f"sudo chown root:root {task.destination}",
        f"sudo chmod {task.mode} {task.destination}",
    ]
    ssh_cmd = [
        "ssh",
        "-i",
        str(key_path),
        "-o",
        "StrictHostKeyChecking=no",
        "-o",
        "UserKnownHostsFile=/dev/null",
        f"{user}@{host}",
        " && ".join(remote_commands),
    ]
    print(f"[{node}] {' '.join(ssh_cmd)}")
    if not dry_run:
        subprocess.run(ssh_cmd, check=True)


def main():
    parser = argparse.ArgumentParser(description="Distribute PKI assets to nodes")
    parser.add_argument("--manifest", default="chapter3/pki/manifest.yaml", type=Path)
    parser.add_argument("--inventory", default="chapter2/inventory.yaml", type=Path)
    parser.add_argument("--ssh-key", type=Path, help="Path to SSH private key; defaults to inventory metadata")
    parser.add_argument("--user", help="SSH username; defaults to inventory metadata")
    parser.add_argument("--nodes", nargs="*", help="Limit distribution to specific nodes")
    parser.add_argument("--dry-run", action="store_true", help="Print actions without executing")

    args = parser.parse_args()

    manifest_path = args.manifest.resolve()
    inventory_path = args.inventory.resolve()

    manifest_tasks = collect_tasks(manifest_path)

    inventory = load_yaml(inventory_path)
    node_map = build_node_map(inventory)
    ssh_user = args.user or inventory.get("metadata", {}).get("ssh_user", "ubuntu")
    default_key = inventory.get("metadata", {}).get("ssh_key_path")
    ssh_key_path = args.ssh_key or (inventory_path.parent / default_key if default_key else None)

    if not ssh_key_path:
        print("[ERROR] No SSH key path provided or found in inventory", file=sys.stderr)
        raise SystemExit(1)

    ssh_key_path = ssh_key_path.resolve()
    if not ssh_key_path.exists():
        print(f"[ERROR] SSH key not found at {ssh_key_path}", file=sys.stderr)
        raise SystemExit(1)

    selected_nodes = set(args.nodes or [])

    for task in manifest_tasks:
        if task.node != "bastion" and task.node not in node_map:
            print(f"[WARN] Node '{task.node}' not found in inventory; skipping")
            continue

        if selected_nodes and task.node not in selected_nodes:
            continue

        if not task.source.exists():
            print(f"[WARN] Source file missing: {task.source}; skipping")
            continue

        if task.is_local:
            run_local(task, args.dry_run)
        else:
            host = node_map[task.node]
            scp_to_remote(task, task.node, ssh_user, host, ssh_key_path, args.dry_run)

    print("[DONE] Distribution routine complete")


if __name__ == "__main__":
    main()
