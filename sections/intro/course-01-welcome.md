# Welcome To The Course

This course trains you for the **Fundamentals, Architecture & CLI Operations** part of the Astrona **OpenBao** training path. That part is 10% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, pods, Secrets, `kubectl get`, `kubectl logs` and `kubectl exec`. You have installed something with Helm before, and you can read a short configuration file. You do not need to know OpenBao or HashiCorp Vault. Each new idea is explained the first time it appears.

## What you can do at the end

OpenBao is a server you run and operate, so this course does not ask you to remember words. It asks you to start the server, bring it into a usable state, and find out why when it is not usable. The course has three topics, and each one turns into a set of skills you will practise.

The first topic is **how OpenBao protects data**. You will learn to:

- Explain what OpenBao is, where it comes from, and how a request travels through it.
- Explain the barrier, the keyring, the root key and Shamir's secret sharing.
- Read the seal state and the health of a server, and unseal it with a threshold of key shares.

The server runs from a configuration file, so the second topic is **configuring the server**. You will learn to:

- Write the listener, Integrated Storage and address settings of a server.
- Explain how the Helm chart turns its values into that file, and when the pod must restart.
- Tell a development server from a real one, and move from one to the other.

The third topic is **operating the server with the `bao` command-line tool**. You will learn to:

- Initialize a server with a chosen number of key shares and a threshold.
- Unseal it, sign in, store a first secret and seal it again.
- Rotate the unseal keys and the encryption key, and retire the root token.

Everything is written for **OpenBao v2.7.1**.

## The words this course uses

The pages use OpenBao's and Kubernetes' own terms, because those are the words you meet in the product, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

A **secret** is any value that must stay private, such as a password or a key. **OpenBao** is a server that stores secrets encrypted and decides who may read them. A **sealed** server has its data but not the key to decrypt it, so it answers almost nothing; **unsealing** gives it that key again. A **token** is the credential every request carries, and a **policy** says what a token may do.

Two kinds of keys come back on almost every page:

| Key | What it does |
| --- | --- |
| Unseal key share | One of several pieces that, together with enough others, rebuild the key OpenBao needs to unseal |
| Root token | The first token OpenBao creates; it may do everything, so it is used for setup and then revoked |

## The example setup in your playground

Every playground and lab runs the same small setup. One OpenBao server runs in the namespace `openbao` as the pod `openbao-0`, behind the Service `openbao` on port `8200`. A `tester` pod in the namespace `clients` sends requests to its HTTP API. You run the `bao` command-line tool on your own machine.

Many labs start with a server that is sealed, not initialized or misconfigured on purpose. That is the material, not a fault in the course. Where a lab gives you key shares or a root token in a Kubernetes Secret, that is only so the lab can be graded; a real installation never keeps them there.

## How the course is laid out

The course has three sections. It starts with how OpenBao protects data, then shows the configuration a server runs with, and ends with the commands an operator uses every day.

| Section | What it covers |
| --- | --- |
| 010 | What OpenBao Is And How It Protects Data |
| 020 | Configuring The OpenBao Server |
| 030 | Initializing, Unsealing And Sealing With bao |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
