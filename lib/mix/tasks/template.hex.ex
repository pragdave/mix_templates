# defmodule Mix.Tasks.Template.Hex do
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
# end
