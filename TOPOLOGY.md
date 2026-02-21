<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# No-Nonsense NNTPS — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              NNTP USER                  │
                        │        (Browser / Newsreader GUI)       │
                        └───────────────────┬─────────────────────┘
                                            │
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │           UI LAYER (RESCRIPT)           │
                        │    (TEA Architecture, cadre-tea-router)  │
                        └──────────┬───────────────────┬──────────┘
                                   │                   │
                                   ▼                   ▼
                        ┌───────────────────────┐  ┌────────────────────────────────┐
                        │  ORCHESTRATION LAYER  │  │ STAPELN CONTAINER STACK        │
                        │  (Elixir / OTP)       │  │ - Vörðr Runtime                │
                        │  - GenStateMachine    │  │ - Svalinn Gateway              │
                        │  - Conn Management    │  │ - Selur (Zero-copy IPC)        │
                        └──────────┬────────────┘  └──────────┬─────────────────────┘
                                   │                          │
                                   └────────────┬─────────────┘
                                                ▼
                        ┌─────────────────────────────────────────┐
                        │           NNTPS SERVER (REMOTE)         │
                        │      (Network News over TLS 1.3)        │
                        └─────────────────────────────────────────┘

                        ┌─────────────────────────────────────────┐
                        │          REPO INFRASTRUCTURE            │
                        │  Justfile Automation  .machine_readable/  │
                        │  ABI-FFI Standards    0-AI-MANIFEST.a2ml  │
                        └─────────────────────────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
USER INTERFACE
  ReScript UI (TEA)                 ██████░░░░  60%    Newsgroup browser prototyping
  cadre-tea-router                  ██████████ 100%    Type-safe routing stable
  SafeDOM Mounting                  ██████████ 100%    Proven safe DOMverified

ORCHESTRATION & SECURITY
  Elixir Conn Manager               ████████░░  80%    GenStateMachine stable
  Svalinn Gateway                   ██████████ 100%    Edge auth verified
  Selur IPC                         ██████████ 100%    Zero-copy primitives active
  NNTPS TLS Implementation          ██████████ 100%    Secure-only mode enforced

REPO INFRASTRUCTURE
  Idris2 ABI (Proofs)               ██████████ 100%    Type-level layout verified
  Justfile Automation               ██████████ 100%    Standard build/lint tasks
  .machine_readable/                ██████████ 100%    STATE tracking active

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            ████████░░  ~80%   Secure reader stable, UI refining
```

## Key Dependencies

```
Idris2 ABI ──────► Zig FFI Bridge ──────► Elixir Core ──────► Connection
     │                 │                    │                   │
     ▼                 ▼                    ▼                   ▼
ReScript UI ◄──── SafeDOM ◄───────── cadre-router ◄─────── NNTPS Feed
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
