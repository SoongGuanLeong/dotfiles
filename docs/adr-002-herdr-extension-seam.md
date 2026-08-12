# ADR 002: Herdr Extension Seam

Status: Accepted

## Context

`home/.pi/agent/extensions/herdr-agent-state.ts` claims management by `herdr` and warns of overwrite. This conflicts with the repo's one-owner-per-resource rule.

## Decision

Remove management claim. Treat file as repo-owned fixture.

## Consequences

No overwrite risk. Repo maintains full control.
