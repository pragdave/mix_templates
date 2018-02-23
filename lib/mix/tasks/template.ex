defmodule Mix.Tasks.Template do
  @moduledoc Path.join([__DIR__, "../../../README.md"])
             |> File.read!()
             |> String.replace(~r/\A.*^### Use\w+/ms, "")
             |> String.replace(~r/^###.*/ms, "")

  use Private
  use Mix.Task

  alias MixTemplates.Cache

  @doc nil
  def run([]) do
    Cache.display_list_of_templates()
  end

  def run([template_name]), do: run([template_name, "--help"])
  def run([template_name, "-h"]), do: run([template_name, "--help"])

  def run([template_name, "--help"]) do
    template_name
    |> Cache.find_template()
    |> Cache.display_template_info(:long)
  end
end
