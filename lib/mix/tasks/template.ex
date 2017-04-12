defmodule Mix.Tasks.Template do

  @moduledoc(
    Path.join([__DIR__, "../../../README.md"])
    |> File.read!
    |> String.replace(~r/\A.*^### Use\w+/ms, "")
    |> String.replace(~r/^###.*/ms, ""))

  use Private
  use Mix.Task

  @doc nil
  def run([]) do
    case MixTemplates.Cache.list() do
      [] ->
        Mix.shell.info("""
        No templates installed. 

        Use `mix template.hex' to list templates available in hex, and
        `mix template.install` to install the ones you need.
        """)
      list ->
        Mix.shell.info("\nLocally installed templates:\n")
        Enum.each(list, &display_template_info(&1, :short))
        end
  end

  
  private do

    defp display_template_info(template, :short) do
      Mix.shell.info [ :bright, :green, to_string(template.name), :reset, ":" ]
      Mix.shell.info "\t#{template.short_desc}\n"
    end
    
  end

end
