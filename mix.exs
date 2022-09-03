defmodule MixTemplates.Mixfile do
  use Mix.Project

  @name    :mix_templates
  @version "0.2.3"
  @deps [
    { :private, "> 0.0.0" },
    { :ex_doc,  "~> 0.14", only: :dev, runtime: false },
  ]

  @extra_applications [
    :crypto,
    :eex,
    :hex,
  ]
  @description """
  A modular, open templating system, designed for use with `mix gen`.

  You care about this if:

  ① you'd like different templates than the ones built in to mix,
  ② you'd like to create your own templates, or
  ③ you have created a package such as Phoenix or Nerves that needs
     its own project setup.
  """

  ############################################################

  def project do
    in_production = Mix.env == :prod
     [
      app:     @name,
      version: @version,
      elixir:  ">= 1.4.0",
      deps:    @deps,
      package: package(),
      description:     @description,
      build_embedded:  in_production,
      start_permanent: in_production,
    ]
  end

  def application do
    [
      extra_applications: @extra_applications,
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
      },
      version: @version,
    ]
  end
end
