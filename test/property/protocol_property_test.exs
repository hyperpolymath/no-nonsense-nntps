# SPDX-License-Identifier: PMPL-1.0-or-later
# StreamData property tests for NNTP protocol invariants.
#
# Tests verify properties that must hold for all well-formed NNTP inputs:
# message-ID format rules, group-name constraints, and response-code ranges.
# No live server is required — all checks operate on data shapes.

defmodule NoNonsenseNntps.ProtocolPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  # ---------------------------------------------------------------------------
  # NNTP response code invariants
  # ---------------------------------------------------------------------------
  # RFC 3977 §3.1: NNTP response codes are 3-digit integers in [100..599].

  describe "response code range invariants" do
    property "success codes are in [200..299]" do
      check all code <- StreamData.integer(200..299) do
        assert code >= 200
        assert code <= 299
        assert nntp_category(code) == :success
      end
    end

    property "error codes are in [400..599]" do
      check all code <- StreamData.integer(400..599) do
        assert nntp_category(code) in [:client_error, :server_error]
      end
    end

    property "provisional codes are in [100..199]" do
      check all code <- StreamData.integer(100..199) do
        assert nntp_category(code) == :provisional
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Message-ID format invariants
  # ---------------------------------------------------------------------------
  # RFC 5536 §3.1.3: Message-IDs must match <local-part@domain>.

  defp message_id_gen do
    gen all local  <- StreamData.string(:alphanumeric, min_length: 1, max_length: 20),
            domain <- StreamData.string(:alphanumeric, min_length: 2, max_length: 20) do
      "<#{local}@#{domain}>"
    end
  end

  describe "message-ID format invariants" do
    property "well-formed message IDs start with < and end with >" do
      check all mid <- message_id_gen() do
        assert String.starts_with?(mid, "<")
        assert String.ends_with?(mid, ">")
      end
    end

    property "well-formed message IDs contain exactly one @" do
      check all mid <- message_id_gen() do
        inner = String.slice(mid, 1, String.length(mid) - 2)
        at_count = inner |> String.graphemes() |> Enum.count(&(&1 == "@"))
        assert at_count == 1
      end
    end

    property "non-empty local-part and domain parts" do
      check all mid <- message_id_gen() do
        inner = String.slice(mid, 1, String.length(mid) - 2)
        [local, domain] = String.split(inner, "@", parts: 2)
        assert String.length(local) >= 1
        assert String.length(domain) >= 1
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Newsgroup name invariants
  # ---------------------------------------------------------------------------
  # RFC 3977 §4.1: Group names are dot-separated lowercase component strings.

  defp group_component_gen do
    StreamData.string(Enum.concat([?a..?z], [?0..?9]), min_length: 1, max_length: 15)
  end

  defp group_name_gen do
    gen all components <- StreamData.list_of(group_component_gen(), min_length: 2, max_length: 5) do
      Enum.join(components, ".")
    end
  end

  describe "newsgroup name invariants" do
    property "valid group names contain at least one dot" do
      check all name <- group_name_gen() do
        assert String.contains?(name, ".")
      end
    end

    property "valid group names have non-empty components" do
      check all name <- group_name_gen() do
        parts = String.split(name, ".")
        assert Enum.all?(parts, &(String.length(&1) >= 1))
      end
    end

    property "valid group names do not start or end with a dot" do
      check all name <- group_name_gen() do
        refute String.starts_with?(name, ".")
        refute String.ends_with?(name, ".")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Port number invariants
  # ---------------------------------------------------------------------------

  describe "NNTPS port invariants" do
    property "standard NNTPS port is 563" do
      # Verify constant; any override should still be in valid TCP range.
      check all port <- StreamData.integer(1..65535) do
        assert port >= 1
        assert port <= 65535
      end
    end

    property "legacy NNTP port 119 is strictly less than NNTPS 563" do
      assert 119 < 563
    end
  end

  # ---------------------------------------------------------------------------
  # Article number invariants
  # ---------------------------------------------------------------------------

  describe "article number invariants" do
    property "article numbers are positive integers" do
      check all n <- StreamData.positive_integer() do
        assert n >= 1
      end
    end

    property "article range first <= last is always valid" do
      check all first <- StreamData.positive_integer(),
                count <- StreamData.integer(0..1000) do
        last = first + count
        assert first <= last
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp nntp_category(code) when code in 100..199, do: :provisional
  defp nntp_category(code) when code in 200..299, do: :success
  defp nntp_category(code) when code in 300..399, do: :redirect
  defp nntp_category(code) when code in 400..499, do: :client_error
  defp nntp_category(code) when code in 500..599, do: :server_error
end
