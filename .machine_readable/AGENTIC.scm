;; SPDX-License-Identifier: PMPL-1.0-or-later
;; AGENTIC.scm - AI agent interaction patterns for no-nonsense-nntps

(define agentic-config
  `((version . "1.0.0")
    (project . "no-nonsense-nntps")
    (claude-code
      ((model . "claude-sonnet-4-5-20250929")
       (tools . ("read" "edit" "bash" "grep" "glob" "task"))
       (permissions . "read-all")))
    (patterns
      ((code-review . "thorough")
       (refactoring . "conservative")
       (testing . "comprehensive")
       (security-first . "always-verify-tls")
       (formal-verification . "use-proven-library")))
    (constraints
      ((languages . ("elixir" "rescript" "idris2" "zig"))
       (banned . ("typescript" "go" "python" "makefile"))
       (protocol . "nntps-only")
       (no-insecure . "nntp")))
    (tech-stack
      ((backend . "elixir")
       (frontend . "rescript-tea")
       (routing . "cadre-tea-router")
       (security . ("svalinn" "vordr" "cerro-torre" "selur"))
       (verification . "proven")
       (deployment . "k9-svc")))
    (development-priorities
      ((security . "paramount")
       (formal-verification . "where-applicable")
       (type-safety . "end-to-end")
       (performance . "optimize-via-selur")))))
