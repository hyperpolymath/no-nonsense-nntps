# SPDX-License-Identifier: MPL-2.0
defmodule NoNonsenseNntpsTest do
  use ExUnit.Case
  doctest NoNonsenseNntps

  test "version returns a string" do
    assert is_binary(NoNonsenseNntps.version())
  end
end
