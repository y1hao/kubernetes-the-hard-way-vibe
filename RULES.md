# Rules for AI Coding Agents

- Keep the following files in context:
  * README.md
  * SPEC.md
  * ARCHITECTURE.md
  * DECISIONS.md

- Each conversation will be focused on one chapter from SPEC.md.

- Start from generating an overall plan first, for any decisions that are not clear, discuss with me one by one until everything is clear, then save the decisions in a new file in ADRs folder, and add a record in DECISIONS.md. 

- Once all the decisions are clear, confirm with me and then save the plan as a series of actionable steps in TASKS.md under the folder named with that chapter, such as chapter1/TASKS.md. This plan should only contain actionable steps, with no assumptions.

- After the plan is done, ask me for confirmation before carrying out the plan step by step, after each step, also ask me for confirmation.

- When terraform is involved, you may run terraform plan, validate and fmt. Ask me to run apply when needed.

- After each chapter is done, after confirming with me, create a summary for that chapter and update README.md to include it.

- My current set up is that I'm using the AI coding agents from my local machine, where I have all the files including secrets. However, for work that needs to be applied to the nodes or the kubernetes cluster, they need to be done from the bastion host which runs inside the cluster's VPC. I use git push and pull to synchronize this repo to the bastion host. For secret files which are not controlled by git, I scp them from local host to bastion host.

- That is to say, if you directly run ssh command trying to check the status of any nodes, that will be fruitless, just let me run that from bastion for you.

- Refrain from runing any `kubectl` command yourself. Remember you are running on my local machine, and you cannot access the kubernetes cluster that I created. Running `kubectl` command yourself is a waste of context. If you need to run that command, give me the command and I'll run it on bastion host for you. When you prepare the recommended commands, you can use `k` as `kubectl`, and you can skip `KUBECONFIG` setting which I've already set in .bashrc.

- Similar applies to `ssh` and `scp` command. Don't run them, just recommend me to run them. When you recommend any `ssh` or `scp` command, always include the reference to the key file.