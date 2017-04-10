defmodule MixTemplates.Mixfile do
  use Mix.Project

  @name    :mix_templates
  @version "0.1.0"
  @deps [
    private: "> 0.0.0"
    ex_doc:  [ "~> 0.14", only: :dev, runtime: false ],
  ]

  @description """
  A modular, open templating system. It's designed for use with 
  `mix gen`, but could probably be used elsewhere. 

  You care about this if ① you'd like to use project templates that
  are the ones built in to mix, ② you'd like to create your own
  templates, or ③ you have created a package such as Phoenix or Nerves
  that need their own project setup.
  """
  
  ############################################################
  
  def project do
    in_production = Mix.env == :prod
    [
      app:     @name,
      version: @version,
      elixir:  "~> 1.4",
      deps:    @deps,
      package: package(),
      description:     @description,
      build_embedded:  in_production,
      start_permanent: in_production,
    ]
  end


  defp package do
    [
      files: [
        "lib", "mix.exs", "README.md"
      ],
      maintainers: [
        "Dave Thomas <dave@pragdave.me>"
      ],
      licenses: [
        "Apache 2 (see the file LICENSE.md for details)"
      ],
      links: %{
        "GitHub" => "https://github.com/pragdave/mix_templates",
      }
    ]
  end
  
end
