# SPDX-License-Identifier: PMPL-1.0-or-later

defmodule NoNonsenseNntps.ClientManager do
  @moduledoc """
  NNTPS Client Manager — High-Assurance Connection Orchestrator.

  This module acts as the "Logical Socket" for the NNTPS application. 
  It abstracts the lifecycle of the underlying connection process, 
  providing a stable API for the web and mobile frontends.

  ## Managed Workflows:
  1. **Connectivity**: Establishes TLS-secured links to Usenet servers.
  2. **discovery**: Retrieves the authoritative list of newsgroups.
  3. **Retrieval**: Orchestrates the fetching of articles and headers.
  4. **State Tracking**: Ensures that only one active client instance 
     is maintained per user session.
  """

  use GenServer
  require Logger

  @client_name :nntps_client

  # --- CLIENT API ---

  @doc """
  CONNECT: Initiates a TLS session with the target news server.
  Note: Port defaults to 563 (NNTPS standard).
  """
  def connect(host, port \\ 563) do
    GenServer.call(__MODULE__, {:connect, host, port})
  end

  @doc """
  LIST: Fetches the directory of available newsgroups from the server.
  """
  def list_groups do
    GenServer.call(__MODULE__, :list_groups, 60_000)
  end

  # --- SERVER CALLBACKS ---

  @impl true
  def handle_call({:connect, host, port}, _from, state) do
    # IDEMPOTENCY: Shuts down any existing client before starting a new one.
    if state.client_pid, do: NoNonsenseNntps.Client.disconnect(state.client_pid)

    case NoNonsenseNntps.Client.start_link(host: host, port: port, name: @client_name) do
      {:ok, pid} -> 
        # ... [Success handling]
        {:reply, {:ok, :connected}, %{state | client_pid: pid, host: host, port: port}}
      _ -> {:reply, {:error, :failed}, state}
    end
  end
end
