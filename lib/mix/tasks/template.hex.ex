defmodule Mix.Tasks.Template.Hex do

  use Private

  @moduledoc(
    Path.join([__DIR__, "../../../README.md"])
    |> File.read!
    |> String.replace(~r/\A.*^### Use\w+/ms, "")
    |> String.replace(~r/^###.*/ms, ""))

  def run(_) do
    "gen_template"
    |> Hex.API.Package.search
    |> extract_stuff_we_need
    |> display_results
  end

  private do

    defp extract_stuff_we_need({200, content, _}) do
      content
      |> Enum.filter(&is_a_template?/1)
    end

    defp extract_stuff_we_need({error, _, _}) do
      Mix.raise "error #{error} while searching hex packages"
    end

    defp is_a_template?(%{ "name" => name }) do
      name |> String.starts_with?("gen_template_")
    end

    defp display_results([]) do
      Mix.shell.info "Strange... no templates found on hex.pm"
    end

    defp display_results(results) do
      Mix.shell.info(["\n", :underline, "Templates on hex.pm", :reset, "\n"])
      results |> Enum.each(&display_a_result/1)
      Mix.shell.info("Install a template using `mix template.install «name»`\n")
    end

    defp display_a_result(%{ "name" => name,
                             "meta" =>  %{
                               "description" => description
                             }}) do
      Mix.shell.info([:bright, :green, name,
                      :reset, ":\n",
                      indent(description)])
      
    end

    defp indent(string) do
      "    #{String.replace(string, "\n", "\n    ") |> String.trim_trailing}\n"
    end
  end
end

# 
#   @moduledoc """
#   Manage the local installation and uninstallation of templates used
#   by `mix gen`.
# 
#   Usage:
# 
#   * `mix template [list]`
# 
#     List the locally installed templates.
# 
#   * `mix template.hex`
# 
#     List the templates available on hex.
# 
#   * `mix template.install «source»`
# 
#     Install a template from source.
# 
#   * `mix template.uninstall «name»`
# 
#     Uninstall the template with the given name.
# 
#   The «source» can be
# 
#   * the name of a Hex project containing the template
# 
#   * a local file path (starting with a `.` or `/`)
# 
#   Templates are installed in MIX_HOME/templates (by default ~/.mix/templates).    
# 
#   See `Mix.Tasks.Gen` for details on how to use these templates.
# 
#   """
# 
#   use Private
#   
#   use Mix.Task
# 
# #  @behaviour Mix.Local.Installer
#   
#   @doc nil
#   def run([ ]) do
#     run(["list"])
#   end
# 
#   def run([ "list" ]) do
#     case MixTemplates.Cache.list() do
#       [] ->
#         Mix.shell.info "No templates installed. Use `mix template install` to get some"
#       list ->
#         Enum.each(list, &display_template_info(&1, :short))
#         end
#   end
# 
#   def run([ "install", source ]) do
#     case MixTemplates.TemplateInstall.install(source) do
#       { :error, reason } ->
#         Mix.shell.error [ :red, "Error: ", :reset, "installing #{source}—#{reason}" ]
#       { :ok, project } ->
#         Mix.shell.info("template “#{project}” installed")
#       other ->
#         raise inspect other
#     end
#   end
# 
#   def run([ "uninstall", source ]) do
#     case MixTemplates.TemplateInstall.uninstall(source) do
#       { :error, reason } ->
#         Mix.shell.error [ :red, "Error: ", :reset, "uninstalling #{source}—#{reason}" ]
#       { :ok, project } ->
#         Mix.shell.info("template “#{project}” uninstalled")
#       other ->
#         raise inspect other
#     end
#   end
#   
#   def run(_other) do
#     usage()
#   end
#   
#   private do
# 
#     defp display_template_info(template, :short) do
#       Mix.shell.info [ :bright, :green, to_string(template.name), :reset, ":" ]
#       Mix.shell.info "\t#{template.short_desc}\n"
#     end
#     
#     defp error(message) do
#       Mix.shell.error(message)
#       usage()
#     end
#       
#     defp usage() do
#       IO.puts "Usage:\n"
# 
#       Mix.Task.moduledoc(__MODULE__)
#       |> String.split(~r/Usage:\s*/m)
#       |> Enum.at(1)
#       |> IO.puts
#       
#       exit(:normal)
#     end
#   end
# 

