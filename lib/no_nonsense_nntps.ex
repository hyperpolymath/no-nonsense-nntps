# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule NoNonsenseNntps do
  @moduledoc """
  No-Nonsense NNTPS — Verified, secure Usenet client.

  This application implements a modern NNTP client that mandates TLS encryption 
  (NNTPS) and leverages formally verified components for critical logic.

  ## Architecture Pillars
  1. **Security**: Mandatory TLS and integration with the Svalinn auth stack.
  2. **Reliability**: GenStateMachine for robust connection and retry logic.
  3. **Verification**: Uses Idris2-based URL and protocol parsers to eliminate
     common parsing vulnerabilities.
  """

  use Application
  require Logger

  @doc """
  Returns the current version from the application specification.
  """
  def version do
    {:ok, vsn} = :application.get_key(:no_nonsense_nntps, :vsn)
    List.to_string(vsn)
  end

  @impl true
  def start(_type, _args) do
    # CONFIGURATION: Determine port from env or default to 4000.
    port = String.to_integer(System.get_env("PORT") || "4000")

    # SUPERVISION TREE:
    # 1. ClientManager: Tracks active newsgroup connections and sessions.
    # 2. Bandit: High-performance HTTP/1.1 and HTTP/2 server for the UI API.
    children = [
      {NoNonsenseNntps.ClientManager, []},
      {Bandit, plug: NoNonsenseNntps.API, scheme: :http, port: port}
    ]

    opts = [strategy: :one_for_one, name: NoNonsenseNntps.Supervisor]
    Logger.info("Starting no-nonsense-nntps secure gateway on port #{port}")
    Supervisor.start_link(children, opts)
  end
end
