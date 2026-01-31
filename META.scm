;; SPDX-License-Identifier: PMPL-1.0-or-later
;; META.scm - Architectural decisions and project meta-information
;; Media-Type: application/meta+scheme

(define-meta no-nonsense-nntps
  (version "1.0.0")

  (architecture-decisions
    ;; ADR format: (adr-NNN status date context decision consequences)
    ((adr-001 accepted "2026-01-31"
      "Need secure newsgroup reader for modern content formats"
      "Build NNTPS-only reader on verified container ecosystem with Elixir + ReScript TEA"
      "Ensures security by design (no insecure NNTP). Elixir provides robust "
      "connection management with GenStateMachine. ReScript TEA gives type-safe UI. "
      "Verified container stack (Svalinn/Vörðr/Cerro Torre/Selur) provides end-to-end security.")

    (adr-002 accepted "2026-01-31"
      "Traditional NNTP readers only support plain text articles"
      "Support multiplicity of content forms: plain text, HTML, Markdown, rich media"
      "Modern newsgroups may contain diverse content. Parser abstraction allows "
      "pluggable format support. UI can render multiple formats safely.")

    (adr-003 accepted "2026-01-31"
      "NNTPS protocol requires TLS certificate verification"
      "Use Cerro Torre for certificate provenance verification"
      "Cerro Torre provides cryptographic verification with Ed25519 signatures "
      "and formal SPARK proofs. Ensures trust chain validation.")

    (adr-004 accepted "2026-01-31"
      "Need formal verification for URL parsing in routing"
      "Integrate proven library (Idris2) via cadre-tea-router"
      "cadre-tea-router uses ProvenSafeUrl for mathematically proven URL parsing. "
      "Eliminates entire class of URL-based vulnerabilities.")

    (adr-005 proposed "2026-01-31"
      "Performance optimization for IPC between UI and NNTPS client"
      "Use Selur (WASM zero-copy IPC) for high-throughput article streaming"
      "Eliminates JSON serialization overhead. 3.3x latency improvement. "
      "Linear types prevent memory leaks. Needs implementation validation.")))

  (development-practices
    (code-style
      "Follow hyperpolymath language policy: "
      "Prefer ReScript, Rust, Gleam, Elixir. "
      "Avoid TypeScript, Go, Python per RSR.")
    (security
      "All commits signed. "
      "Hypatia neurosymbolic scanning enabled. "
      "OpenSSF Scorecard tracking.")
    (testing
      "Comprehensive test coverage required. "
      "CI/CD runs on all pushes.")
    (versioning
      "Semantic versioning (semver). "
      "Changelog maintained in CHANGELOG.md.")
    (documentation
      "README.adoc for overview. "
      "STATE.scm for current state. "
      "ECOSYSTEM.scm for relationships.")
    (branching
      "Main branch protected. "
      "Feature branches for new work. "
      "PRs required for merges."))

  (design-rationale
    (why-rsr
      "RSR provides standardized structure across 500+ repos, "
      "enabling automated tooling and consistent developer experience.")
    (why-hypatia
      "Neurosymbolic security scanning combines neural pattern recognition "
      "with symbolic reasoning for fast, deterministic security checks.")
    (why-elixir
      "Elixir provides fault-tolerant connection management with GenServer/GenStateMachine. "
      "BEAM VM excels at concurrent network I/O. Supervisors handle connection recovery.")
    (why-rescript-tea
      "Type-safe UI prevents runtime errors. TEA architecture provides predictable "
      "state updates. Formally verified via proven library integration.")
    (why-nntps-only
      "Security by design - no legacy insecure protocol support. "
      "All newsgroup connections encrypted with TLS 1.3. "
      "Certificate verification via Cerro Torre.")
    (why-verified-stack
      "Svalinn provides auth/policy enforcement at edge. "
      "Vörðr enables reversible container operations. "
      "Cerro Torre ensures provenance. "
      "Selur optimizes IPC performance. "
      "End-to-end formal verification eliminates vulnerability classes."))))
