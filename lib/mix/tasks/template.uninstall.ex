defmodule Mix.Tasks.Template.Uninstall do
  @moduledoc Path.join([__DIR__, "../../../README.md"])
             |> File.read!()
             |> String.replace(~r/\A.*^### Use\w+/m, "")
             |> String.replace(~r/^###.*/m, "")

  use Private
  use Mix.Task
  alias MixTemplates.Cache

  def run([source]) do
    case uninstall(source) do
      {:error, reason} ->
        Mix.shell().error([
          :red,
          "Error: ",
          :reset,
          "uninstalling template “#{source}:” #{reason}"
        ])

      {:ok, project} ->
        Mix.shell().info("template “#{project}” uninstalled")

      other ->
        raise inspect(other)
    end
  end

  defp uninstall(project) do
    if MixTemplates.find(project) do
      Cache.uninstall_template(project)
    else
      {:error, "template “#{project}” is not installed"}
    end
  end
end
