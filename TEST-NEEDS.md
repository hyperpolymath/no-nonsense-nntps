# TEST-NEEDS.md — no-nonsense-nntps

> Generated 2026-03-29 by punishing audit.

## Current State

| Category     | Count | Notes |
|-------------|-------|-------|
| Unit tests   | 1     | test/no_nonsense_nntps_test.exs |
| Integration  | 1     | ffi/zig/test/integration_test.zig |
| E2E          | 0     | None |
| Benchmarks   | 0     | None |

**Source modules:** ~19 source files. 4 Elixir lib modules, 12 ReScript frontend modules, 3 Idris2 ABI, 1 Zig FFI.

## What's Missing

### P2P (Property-Based) Tests
- [ ] NNTP protocol: property tests for message format compliance (RFC 3977)
- [ ] Article parsing: arbitrary article content fuzzing
- [ ] Group listing: property tests for group name validation

### E2E Tests
- [ ] Full NNTP session: connect -> authenticate -> list groups -> read article -> post -> disconnect
- [ ] Frontend: user interaction flow through ReScript UI
- [ ] ABI/FFI round-trip verification

### Aspect Tests
- **Security:** No tests for authentication bypass, article injection, buffer overflow in protocol parsing
- **Performance:** No throughput benchmarks for article retrieval/posting
- **Concurrency:** No tests for concurrent NNTP sessions
- **Error handling:** No tests for malformed NNTP commands, disconnection handling, invalid article format

### Build & Execution
- [ ] `mix test` for Elixir
- [ ] ReScript build verification
- [ ] Zig FFI test execution

### Benchmarks Needed
- [ ] Article retrieval latency
- [ ] Concurrent session throughput
- [ ] Protocol parsing speed

### Self-Tests
- [ ] NNTP protocol compliance self-check
- [ ] ABI version agreement

## Priority

**HIGH.** A network protocol server (NNTP) with 1 unit test and 1 FFI integration test. Network protocol implementations need extensive testing for security and compliance. 19 modules, 2 tests = 10.5% file coverage.

## FAKE-FUZZ ALERT

- `tests/fuzz/placeholder.txt` is a scorecard placeholder inherited from rsr-template-repo — it does NOT provide real fuzz testing
- Replace with an actual fuzz harness (see rsr-template-repo/tests/fuzz/README.adoc) or remove the file
- Priority: P2 — creates false impression of fuzz coverage
