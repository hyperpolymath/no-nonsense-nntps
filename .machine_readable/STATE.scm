;; SPDX-License-Identifier: PMPL-1.0-or-later
;; STATE.scm - Project state tracking for no-nonsense-nntps
;; Media-Type: application/vnd.state+scm

(define-state no-nonsense-nntps
  (metadata
    (version "0.1.0")
    (schema-version "1.0.0")
    (created "2026-01-31")
    (updated "2026-01-31")
    (project "no-nonsense-nntps")
    (repo "hyperpolymath/no-nonsense-nntps"))

  (project-context
    (name "no-nonsense-nntps")
    (tagline "Modern secure NNTPS reader with formally verified components")
    (tech-stack
      "Elixir (orchestration, connection management)"
      "ReScript TEA (UI framework)"
      "cadre-tea-router (routing)"
      "Svalinn (edge gateway)"
      "Vörðr (container runtime)"
      "Cerro Torre (provenance)"
      "Selur (zero-copy IPC)"
      "Proven library (formal verification)"))

  (current-position
    (phase "initialization")
    (overall-completion 5)
    (components
      ("Elixir NNTPS client" . 0)
      ("ReScript TEA UI" . 0)
      ("Security stack integration" . 0)
      ("Article parser (modern formats)" . 0))
    (working-features ()))

  (route-to-mvp
    (milestones
      ((name "Initial Setup")
       (status "in-progress")
       (completion 80)
       (items
         ("Initialize repository from rsr-template-repo" . done)
         ("Initialize Elixir project structure" . done)
         ("Define NNTPS client architecture" . todo)
         ("Set up ReScript TEA integration" . todo)))
      ((name "NNTPS Core Protocol")
       (status "pending")
       (completion 0)
       (items
         ("Implement TLS connection handling" . todo)
         ("Implement NNTPS commands (GROUP, ARTICLE, etc.)" . todo)
         ("Connection pooling with GenServer" . todo)
         ("Article fetching and caching" . todo)))
      ((name "UI Foundation")
       (status "pending")
       (completion 0)
       (items
         ("ReScript TEA app structure" . todo)
         ("Newsgroup browser component" . todo)
         ("Article viewer (multi-format)" . todo)
         ("cadre-tea-router integration" . todo)))
      ((name "Security Integration")
       (status "pending")
       (completion 0)
       (items
         ("Svalinn auth integration" . todo)
         ("Vörðr container runtime integration" . todo)
         ("Certificate verification via Cerro Torre" . todo)
         ("Proven library for URL parsing" . todo)))))

  (blockers-and-issues
    (critical ())
    (high
      "Need k9-svc deployment patterns"
      "Need a2ml integration patterns")
    (medium
      "Determine modern content format support (beyond plain text)")
    (low ()))

  (critical-next-actions
    (immediate
      "Design NNTPS client GenServer architecture"
      "Set up ReScript project structure"
      "Define article format specs")
    (this-week
      "Implement basic NNTPS connection"
      "Create TEA app scaffold"
      "Integrate proven library for safe URL parsing")
    (this-month
      "Working NNTPS connection with article fetch"
      "Basic UI with newsgroup browser"
      "Security stack integration (Svalinn auth)"))

  (session-history ()))

;; Helper functions
(define (get-completion-percentage state)
  (current-position 'overall-completion state))

(define (get-blockers state severity)
  (blockers-and-issues severity state))

(define (get-milestone state name)
  (find (lambda (m) (equal? (car m) name))
        (route-to-mvp 'milestones state)))
