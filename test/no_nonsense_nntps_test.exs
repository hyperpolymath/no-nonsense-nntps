# SPDX-License-Identifier: PMPL-1.0-or-later
defmodule NoNonsenseNntpsTest do
  use ExUnit.Case
  doctest NoNonsenseNntps

  test "version returns a string" do
    assert is_binary(NoNonsenseNntps.version())
  end
end
