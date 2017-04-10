defmodule Project.Mixfile do
  use Mix.Project

  @name    :two
  @version "0.1.0"
  
  @deps [
    templates: "mix_templates", "> 0.0.0",
  ]

  
  ############################################################
  
  def project do
    in_production = Mix.env == :prod
    [
      app:     @name,
      version: @version,
      elixir:  "~> 1.4",
      deps:    @deps,
      build_embedded:  in_production,
      start_permanent: in_production,
    ]
  end
end
