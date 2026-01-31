;; SPDX-License-Identifier: PMPL-1.0-or-later
;; ECOSYSTEM.scm - Ecosystem relationships for no-nonsense-nntps
;; Media-Type: application/vnd.ecosystem+scm

(ecosystem
  (version "1.0.0")
  (name "no-nonsense-nntps")
  (type "application")
  (purpose "Modern secure NNTPS newsgroup reader with formally verified components")

  (position-in-ecosystem
    "User-facing application built on the hyperpolymath verified container "
    "ecosystem (Svalinn, Vörðr, Cerro Torre, Selur) and formally verified "
    "libraries (proven, rescript-tea, cadre-tea-router). Demonstrates "
    "end-to-end security from protocol layer to UI.")

  (related-projects
    (dependency "svalinn" "Edge gateway and authentication")
    (dependency "vordr" "Container runtime with reversibility")
    (dependency "cerro-torre" "Provenance verification")
    (dependency "selur" "Zero-copy IPC bridge")
    (dependency "rescript-tea" "TEA framework")
    (dependency "cadre-tea-router" "Proven-safe URL routing")
    (dependency "proven" "Idris2 formally verified library")
    (dependency "k9-svc" "Kubernetes service framework")
    (dependency "a2ml" "Adaptive ML framework")
    (inspiration "SeaMonkey" "Traditional NNTP reader interface inspiration"))

  (what-this-is
    "A modern, security-first NNTPS reader that only supports encrypted "
    "newsgroup connections (NNTPS). Built with Elixir for connection "
    "management and ReScript TEA for a type-safe UI. Integrates with the "
    "hyperpolymath verified container ecosystem for end-to-end security. "
    "Designed to support modern content formats beyond plain text while "
    "maintaining NNTP/NNTPS protocol compatibility.")

  (what-this-is-not
    "This is NOT a legacy NNTP reader - it does not support insecure "
    "connections. This is NOT a standalone newsgroup server. This is NOT "
    "a general-purpose email client (no SMTP/IMAP/POP3)."))
