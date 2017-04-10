defmodule Mix.Tasks.Template.Uninstall do

  @moduledoc """
  Manage the local installation and uninstallation of templates used
  by `mix gen`.

  Usage:

  * `mix template [list]`

    List the locally installed templates.

  * `mix template.hex`

    List the templates available on hex.

  * `mix template.install «source»`

    Install a template from source.

  * `mix template.uninstall «name»`

    Uninstall the template with the given name.

  The «source» can be

  * the name of a Hex project containing the template

  * a local file path (starting with a `.` or `/`)

  Templates are installed in MIX_HOME/templates (by default ~/.mix/templates).    

  See `Mix.Tasks.Gen` for details on how to use these templates.

  """
  use Private
  use Mix.Task
  alias MixTemplates.Cache

  def run([ source ]) do
    case uninstall(source) do
      { :error, reason } ->
        Mix.shell.error([ :red, "Error: ",
                          :reset, "uninstalling template “#{source}:” #{reason}" ])
      { :ok, project } ->
        Mix.shell.info("template “#{project}” uninstalled")

      other ->
        raise inspect other
    end
  end


  defp uninstall(project) do
    if MixTemplates.find(project) do
      Cache.uninstall_template(project)
    else
      { :error, "template “#{project}” is not installed" }
    end
  end
  
end
