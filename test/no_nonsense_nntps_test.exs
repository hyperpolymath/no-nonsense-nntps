# SPDX-License-Identifier: MPL-2.0
# Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
defmodule NoNonsenseNntpsTest do
  use ExUnit.Case
  doctest NoNonsenseNntps

  test "version returns a string" do
    assert is_binary(NoNonsenseNntps.version())
  end
end
