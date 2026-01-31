;; SPDX-License-Identifier: PMPL-1.0-or-later
;; PLAYBOOK.scm - Operational runbook for no-nonsense-nntps

(define playbook
  `((version . "1.0.0")
    (project . "no-nonsense-nntps")
    (procedures
      ((build-backend . (("compile-elixir" . "mix compile")
                         ("run-tests" . "mix test")
                         ("format" . "mix format")))
       (build-frontend . (("compile-rescript" . "deno task build")
                          ("watch-mode" . "deno task watch")
                          ("clean" . "deno task clean")))
       (deploy . (("k9-svc-deploy" . "k9 deploy production")
                  ("verify-health" . "k9 health-check")
                  ("verify-security" . "hypatia scan --immediate")))
       (rollback . (("vordr-undo" . "vordr undo --last")
                    ("k9-rollback" . "k9 rollback --to-previous")))
       (debug . (("check-nntps-conn" . "mix run -e 'NoNonsenseNntps.Client.debug()'")
                 ("view-logs" . "k9 logs no-nonsense-nntps")
                 ("check-selur-ipc" . "selur debug --show-metrics")))))
    (security-procedures
      ((tls-verification . "cerro-torre verify --strict")
       (certificate-rotation . "cerro-torre rotate-certs")
       (svalinn-auth-check . "svalinn health --auth-status")
       (proven-url-test . "mix test test/proven_url_test.exs")))
    (alerts
      ((connection-failure . "nntps-connection-lost")
       (tls-verification-failed . "critical-tls-failure")
       (hypatia-security-finding . "security-vulnerability-detected")
       (selur-ipc-degradation . "ipc-performance-warning")))
    (contacts
      ((maintainer . "Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>")
       (repository . "https://github.com/hyperpolymath/no-nonsense-nntps")))))
