# ADR 003: Optional Runtimes Policy

## Status

Accepted

## Context

A shared development environment serves users with different language stacks.
Previously the repo had no explicit policy on which runtimes are mandatory vs optional.
This led to ambiguity when adding tools: does every user need this runtime?

## Decision

Language-specific runtimes (Node.js, Java, Scala) are **optional**.
Only the base environment (Nix/Home Manager packages, shell, CLI tools) is required.

Each optional runtime must be managed by its ecosystem's dedicated version manager:

- Node.js → NVM
- Java / Scala → SDKMAN

The shell init must degrade gracefully when an optional runtime is absent
(conditional sourcing, no hard failures).

Python is an exception: `uv` is part of the base environment because Python tooling
is broadly needed across projects.

## Consequences

- Base environment stays lightweight and reproducible.
- Users install only the runtimes they need.
- Shell init must remain defensive — no crashes on missing optional tools.
- Adding a new runtime to the base requires answering: "does every user need this?"
