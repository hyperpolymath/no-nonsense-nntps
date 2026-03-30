# PROOF-NEEDS.md — no-nonsense-nntps

## Current State

- **src/abi/*.idr**: YES — `Types.idr`, `Layout.idr`, `Foreign.idr`
- **Dangerous patterns**: 0
- **LOC**: ~3,500
- **ABI layer**: Complete Idris2 ABI

## What Needs Proving

| Component | What | Why |
|-----------|------|-----|
| TLS-only enforcement | Connection establishment ALWAYS uses TLS | NNTPS-only is a core security invariant |
| Article header parsing | Header parser is total and rejects malformed headers | Malformed headers are an injection vector |
| Thread reconstruction | Thread tree construction is correct and complete | Missing or misplaced articles break discussion view |
| Input sanitisation | User input is properly escaped before display | XSS/injection prevention |

## Recommended Prover

**Idris2** — ABI layer already complete. TLS enforcement is a natural dependent type proof (connection type indexed by TLS state). Header parsing totality can be proven with exhaustive pattern matching.

## Priority

**MEDIUM** — Small, security-focused NNTPS client. TLS-only enforcement is the highest-value proof. The complete ABI layer makes adding proofs straightforward.

## Template ABI Cleanup (2026-03-29)

Template ABI removed -- was creating false impression of formal verification.
The removed files (Types.idr, Layout.idr, Foreign.idr) contained only RSR template
scaffolding with unresolved {{PROJECT}}/{{AUTHOR}} placeholders and no domain-specific proofs.
