# Kubernetes the Hard Way (Vibe Version)

## Motivation

Kubernetes the Hard Way is a classic learning resource for people who want learn Kubernetes seriously. I also followed it when I first learned Kubernetes a couple of years ago. It did give me more familarity and a better mental model of the moving pieces in Kubernetes. However, since the explanations in that tutorial were very brief, for many parts I ended up just following along by copying and pasting the documented bash snippets, without really gaining a thorough understanding. In the end, everything worked, but I still didn't feel 100% confident.

And I realised that's very similar to the experience of vibe coding. So I began to wonder - why don't I just vibe code the whole thing from scratch? In the end, I should get something that works as well, but in the process, I would get to make a lot more decisions, and ask a lot more questions - this should teach me more.

## Approach

The start of everything is this prompt to ChatGPT 5:

```
There is a popular learning resource in the k8s community - kubernetes the hard way, which shows how to bootstrap a cluster in cloud without using a managed offering or out-of-the-box bootstrapper. Now, I want to do something similar, however, instead of following that tutorial, I want to do it by chatting with you. 

Our goals are: 
- Create a kubernetes cluster on AWS 
- We aim to use the minimal offerings from AWS like EC2 and VPCs. We don't use EKS 
- We don't use things like kubeadm. Instead, we manually install everything from source by hand 
- We need to make sure all control plane components are configured correctly so they can talk with each other. This will include certificates are generated and distributed correctly 
- We want to have 3 control plane nodes and 3 worker nodes 
- In the end, we need to be able to create a simple service (nginx is fine) running as a Deployment which we can reach to from the internet 

Doing everything at once is hard. So, let's first start with a high level overview. Please arrange all the things we need to do into several relatively self-contained "chapters". We'll then dig into each "chapter" to get things working gradually.
```

From there, ChatGPT created a detailed roadmap, which I saved in [SPEC.md](./spec.md).

For each chapter, I used Codex to discuss, plan and execute.