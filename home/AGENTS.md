# Global Agent Instructions

Personal preferences that apply across projects.

## Communication

- Be concise.
- State assumptions; surface ambiguity; never guess silently.

## Engineering

- Implement the smallest solution that satisfies the requirement.
- Avoid speculative abstractions and scope creep.
- Prefer simplicity, robustness, maintainability, and scalability over development cost.
- For one-off or infrequent work, prefer a direct end-to-end path over wrappers, control planes, policy layers, or automation unless a concrete need justifies them.

## Bugs

- Reproduce bugs end-to-end, as close to the user's experience as practical, before fixing them.

## Files and commits

- Never use the em dash "—"; use "-".
- Never add the agent as a commit co-author.
- Never manually modify CHANGELOG.md or files marked as auto-generated.

## Subagents

- Before spawning a large swarm of subagents or using a workflow that does so, explain the tradeoffs and ask for explicit approval.

## Environment

- Linux with systemd is the supported environment.
- Keep projects under `~/projects`.
- Use Linux paths for project files.
