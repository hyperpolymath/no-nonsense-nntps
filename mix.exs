# SPDX-License-Identifier: PMPL-1.0-or-later
defmodule NoNonsenseNntps.MixProject do
  use Mix.Project

  def project do
    [
      app: :no_nonsense_nntps,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/hyperpolymath/no-nonsense-nntps",
      homepage_url: "https://github.com/hyperpolymath/no-nonsense-nntps"
    ]
  end

  def application do
    [
      extra_applications: [:logger, :ssl, :crypto]
    ]
  end

  defp deps do
    [
      # NNTPS client will need SSL/TLS support
      {:jason, "~> 1.4"},
      {:telemetry, "~> 1.0"}
    ]
  end

  defp description do
    """
    Modern, secure NNTPS newsgroup reader with formally verified components.
    Built on the hyperpolymath verified container ecosystem (Svalinn, Vörðr, Cerro Torre, Selur).
    """
  end

  defp package do
    [
      name: "no_nonsense_nntps",
      licenses: ["PMPL-1.0-or-later"],
      links: %{"GitHub" => "https://github.com/hyperpolymath/no-nonsense-nntps"},
      maintainers: ["Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>"]
    ]
  end
end
