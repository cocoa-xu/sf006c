defmodule Cirlute.SF006C.MixProject do
  use Mix.Project

  def project do
    [
      app: :cirlute_sf006c,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:cirlute_servo, "~> 0.1.0", github: "cocoa-xu/servo"}
    ]
  end
end
