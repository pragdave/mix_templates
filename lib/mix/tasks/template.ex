defmodule Mix.Tasks.Template do

  @moduledoc """
  Manage the local installation and uninstallation of templates used
  by `mix gen`.

  Usage:

  * `mix template`

    List the locally installed templates.

  * `mix template hex`

    List the templates available on hex.

  * `mix template install «source»`

    Install a template from source.

  * `mix template uninstall «name»`

    Uninstall the template with the given name.

  The «source» can be

  * the name of a Hex project containing the template

  * a local file path (starting with a `.` or `/`)

  Templates are installed in MIX_HOME/templates (by default ~/.mix/templates).    

  See `Mix.Tasks.Gen` for details on how to use these templates.

  """

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
