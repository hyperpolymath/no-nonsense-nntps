# SPDX-License-Identifier: PMPL-1.0-or-later
defmodule NoNonsenseNntps do
  @moduledoc """
  No-Nonsense NNTPS - Modern, secure newsgroup reader.

  A next-generation NNTPS (Network News Transfer Protocol over TLS) client
  built on formally verified components and the hyperpolymath verified
  container ecosystem.

  ## Features

  - **Security-First**: Only supports NNTPS (TLS-encrypted). No insecure NNTP.
  - **Formally Verified**: Built on proven library (Idris2) for unbreakable URL parsing.
  - **Modern Content**: Supports multiple article formats (plain text, HTML, Markdown, rich media).
  - **Verified Stack**: Integrates with Svalinn, Vörðr, Cerro Torre, and Selur.
  - **Type-Safe UI**: ReScript TEA frontend with cadre-tea-router.

  ## Architecture

  - **Elixir Backend**: GenStateMachine for connection management, fault tolerance.
  - **ReScript Frontend**: TEA (The Elm Architecture) for predictable UI.
  - **Security Stack**: Svalinn (auth), Vörðr (runtime), Cerro Torre (provenance), Selur (IPC).
  """

  @doc """
  Returns version information for no-nonsense-nntps.
  """
  def version do
    {:ok, vsn} = :application.get_key(:no_nonsense_nntps, :vsn)
    List.to_string(vsn)
  end
end
