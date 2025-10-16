#!/usr/bin/env python3
"""Distribute cluster assets (PKI, etcd, configs) from the bastion host to nodes.

Reads one or more manifest files describing the artefacts that need to be copied
and leverages `chapter2/inventory.yaml` for node addressing. Designed to run
from the bastion after the repository has been synchronised there.
"""

import argparse
import subprocess
import sys
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Optional

try:
    import yaml  # type: ignore
except ImportError as exc:  # pragma: no cover
    print("[ERROR] PyYAML is required: pip install pyyaml", file=sys.stderr)
    raise SystemExit(1) from exc


DEFAULT_OWNER = "root"
DEFAULT_GROUP = "root"


@dataclass
class Task:
    node: str
    destination: Path
    source: Path
    mode: Optional[str]
    owner: str
    group: str
    is_local: bool
    is_directory: bool
    sensitive: bool


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


def determine_mode(source: Path, *, sensitive: bool, is_directory: bool) -> str:
    if is_directory:
        return "755"
    if sensitive or is_private_key(source):
        return "600"
    return "644"


def create_file_task(
    *,
    node: str,
    source: Path,
    destination: Path,
    explicit_mode: Optional[str],
    owner: str,
    group: str,
    is_local: bool,
    sensitive: bool,
) -> Task:
    mode = explicit_mode or determine_mode(source, sensitive=sensitive, is_directory=False)
    return Task(
        node=node,
        destination=destination,
        source=source,
        mode=mode,
        owner=owner,
        group=group,
        is_local=is_local,
        is_directory=False,
        sensitive=sensitive,
    )


def create_directory_task(
    *,
    node: str,
    source: Path,
    destination: Path,
    explicit_mode: Optional[str],
    owner: str,
    group: str,
    is_local: bool,
    sensitive: bool,
) -> Task:
    mode = explicit_mode or determine_mode(source, sensitive=sensitive, is_directory=True)
    return Task(
        node=node,
        destination=destination,
        source=source,
        mode=mode,
        owner=owner,
        group=group,
        is_local=is_local,
        is_directory=True,
        sensitive=sensitive,
    )


def materialise_tasks(
    *,
    manifest_root: Path,
    entry: dict,
    node: str,
    destination_path: Path,
    owner: str,
    group: str,
    mode: Optional[str],
    sensitive: bool,
) -> List[Task]:
    tasks: List[Task] = []
    is_local = node == "bastion"

    def ensure_path(value: Optional[str]) -> Optional[Path]:
        if not value:
            return None
        return (manifest_root / value).resolve()

    cert_path = ensure_path(entry.get("cert"))
    key_path = ensure_path(entry.get("key"))
    file_path = ensure_path(entry.get("file"))
    generic_path = ensure_path(entry.get("source"))
    directory_path = ensure_path(entry.get("sourceDir"))

    if cert_path:
        tasks.append(
            create_file_task(
                node=node,
                source=cert_path,
                destination=destination_path,
                explicit_mode=entry.get("certMode") or mode,
                owner=entry.get("owner", owner),
                group=entry.get("group", group),
                is_local=is_local,
                sensitive=sensitive,
            )
        )

    if key_path:
        key_dest = destination_path.parent / key_path.name
        tasks.append(
            create_file_task(
                node=node,
                source=key_path,
                destination=key_dest,
                explicit_mode=entry.get("keyMode") or "600",
                owner=entry.get("owner", owner),
                group=entry.get("group", group),
                is_local=is_local,
                sensitive=True,
            )
        )

    if file_path:
        tasks.append(
            create_file_task(
                node=node,
                source=file_path,
                destination=destination_path,
                explicit_mode=entry.get("mode") or mode,
                owner=entry.get("owner", owner),
                group=entry.get("group", group),
                is_local=is_local,
                sensitive=sensitive,
            )
        )

    if generic_path:
        tasks.append(
            create_file_task(
                node=node,
                source=generic_path,
                destination=destination_path,
                explicit_mode=entry.get("mode") or mode,
                owner=entry.get("owner", owner),
                group=entry.get("group", group),
                is_local=is_local,
                sensitive=sensitive,
            )
        )

    if directory_path:
        tasks.append(
            create_directory_task(
                node=node,
                source=directory_path,
                destination=destination_path,
                explicit_mode=entry.get("mode") or mode,
                owner=entry.get("owner", owner),
                group=entry.get("group", group),
                is_local=is_local,
                sensitive=sensitive,
            )
        )

    return tasks


def collect_tasks(manifest_paths: Iterable[Path]) -> List[Task]:
    tasks: List[Task] = []
    for manifest_path in manifest_paths:
        manifest = load_yaml(manifest_path)
        entries = manifest.get("entries", []) or []
        manifest_root = manifest_path.parent

        for entry in entries:
            destination_info = entry.get("destination", {}) or {}
            base_path = destination_info.get("path")
            sensitive = entry.get("sensitive", False)
            default_owner = entry.get("owner", DEFAULT_OWNER)
            default_group = entry.get("group", DEFAULT_GROUP)
            default_mode = entry.get("mode")

            per_node = entry.get("perNode") or {}
            if per_node:
                for node, node_entry in per_node.items():
                    node_dest_raw = node_entry.get("destination", {}).get("path", base_path)
                    if not node_dest_raw:
                        continue
                    node_dest = Path(node_dest_raw)
                    owner = node_entry.get("owner", default_owner)
                    group = node_entry.get("group", default_group)
                    mode = node_entry.get("mode", default_mode)
                    node_sensitive = node_entry.get("sensitive", sensitive)
                    tasks.extend(
                        materialise_tasks(
                            manifest_root=manifest_root,
                            entry=node_entry,
                            node=node,
                            destination_path=node_dest,
                            owner=owner,
                            group=group,
                            mode=mode,
                            sensitive=node_sensitive,
                        )
                    )
            else:
                if not base_path:
                    continue
                destination_path = Path(base_path)
                nodes = destination_info.get("nodes", []) or []
                for node in nodes:
                    tasks.extend(
                        materialise_tasks(
                            manifest_root=manifest_root,
                            entry=entry,
                            node=node,
                            destination_path=destination_path,
                            owner=default_owner,
                            group=default_group,
                            mode=default_mode,
                            sensitive=sensitive,
                        )
                    )

    return tasks


def run_local_file(task: Task, dry_run: bool):
    dest_dir = task.destination.parent
    commands = [
        ["sudo", "mkdir", "-p", str(dest_dir)],
        [
            "sudo",
            "install",
            "-o",
            task.owner,
            "-g",
            task.group,
            "-m",
            task.mode or "644",
            str(task.source),
            str(task.destination),
        ],
    ]
    for cmd in commands:
        print(f"[LOCAL] {' '.join(cmd)}")
        if not dry_run:
            subprocess.run(cmd, check=True)


def run_local_directory(task: Task, dry_run: bool):
    dest_parent = task.destination.parent
    commands = [
        ["sudo", "rm", "-rf", str(task.destination)],
        ["sudo", "mkdir", "-p", str(dest_parent)],
        ["sudo", "cp", "-R", str(task.source), str(dest_parent)],
        [
            "sudo",
            "mv",
            str(dest_parent / task.source.name),
            str(task.destination),
        ],
        [
            "sudo",
            "chown",
            "-R",
            f"{task.owner}:{task.group}",
            str(task.destination),
        ],
    ]
    if task.mode:
        commands.append(["sudo", "chmod", "-R", task.mode, str(task.destination)])

    for cmd in commands:
        print(f"[LOCAL] {' '.join(cmd)}")
        if not dry_run:
            subprocess.run(cmd, check=True)


def run_local(task: Task, dry_run: bool):
    if task.is_directory:
        run_local_directory(task, dry_run)
    else:
        run_local_file(task, dry_run)


def scp_to_remote(task: Task, node: str, user: str, host: str, key_path: Path, dry_run: bool):
    if task.is_directory:
        remote_tmp_dir = f"/tmp/kthw-dist-{uuid.uuid4().hex}"
        ssh_prepare_cmd = [
            "ssh",
            "-i",
            str(key_path),
            "-o",
            "StrictHostKeyChecking=no",
            "-o",
            "UserKnownHostsFile=/dev/null",
            f"{user}@{host}",
            f"mkdir -p {remote_tmp_dir}",
        ]
        print(f"[{node}] {' '.join(ssh_prepare_cmd)}")
        if not dry_run:
            subprocess.run(ssh_prepare_cmd, check=True)

        scp_cmd = [
            "scp",
            "-i",
            str(key_path),
            "-o",
            "StrictHostKeyChecking=no",
            "-o",
            "UserKnownHostsFile=/dev/null",
            "-r",
            str(task.source),
            f"{user}@{host}:{remote_tmp_dir}/",
        ]
        print(f"[{node}] {' '.join(scp_cmd)}")
        if not dry_run:
            subprocess.run(scp_cmd, check=True)

        remote_subdir = f"{remote_tmp_dir}/{task.source.name}"
        remote_commands = [
            f"sudo rm -rf {task.destination}",
            f"sudo mkdir -p {task.destination.parent}",
            f"sudo mv {remote_subdir} {task.destination}",
            f"sudo chown -R {task.owner}:{task.group} {task.destination}",
        ]
        if task.mode:
            remote_commands.append(f"sudo chmod -R {task.mode} {task.destination}")
        remote_commands.append(f"rm -rf {remote_tmp_dir}")
    else:
        remote_tmp = f"/tmp/kthw-dist-{uuid.uuid4().hex}-{task.source.name}"
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
            f"sudo chown {task.owner}:{task.group} {task.destination}",
            f"sudo chmod {task.mode or '644'} {task.destination}",
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


def parse_manifest_args(manifest_args: List[Path]) -> List[Path]:
    if manifest_args:
        return [path.resolve() for path in manifest_args]
    return [Path("chapter3/pki/manifest.yaml").resolve()]


def main():
    parser = argparse.ArgumentParser(description="Distribute cluster assets to nodes")
    parser.add_argument(
        "--manifest",
        action="append",
        type=Path,
        help="Path to a manifest file; repeat for multiple manifests",
    )
    parser.add_argument(
        "--inventory",
        default=Path("chapter2/inventory.yaml"),
        type=Path,
        help="Inventory file describing node addresses",
    )
    parser.add_argument("--ssh-key", type=Path, help="Path to SSH private key; defaults to inventory metadata")
    parser.add_argument("--user", help="SSH username; defaults to inventory metadata")
    parser.add_argument("--nodes", nargs="*", help="Limit distribution to specific nodes")
    parser.add_argument("--dry-run", action="store_true", help="Print actions without executing")

    args = parser.parse_args()

    manifest_paths = parse_manifest_args(args.manifest or [])
    inventory_path = args.inventory.resolve()

    manifest_tasks = collect_tasks(manifest_paths)

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
