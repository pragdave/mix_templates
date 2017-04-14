defmodule MixTemplates.Cache do

  use Private
  
  @moduledoc """
  Manage the cache of local templates. These are stored as Elixir projects
  under `MIX_HOME/templates`.
  """

  @doc """
  Return a list of locally installed templates.
  """

  def list() do
    template_projects()
  end

  @doc """
  Install a local directory tree into the named slot in the cache.
  """

  def install_from_local_tree(source) do
    if is_template?(source) do
      module = load_template_module(source)
      name   = module.name
      target = template_path(name)
      File.mkdir_p!(target)
      File.cp_r!(source, target)
      { :ok, name }
    else
      { :error, "“#{source}” does not contain a valid template" }
    end
  end

  def uninstall_template(project) do
    path = template_path(project)
    cond do
      not is_template?(path) ->
        { :error, "#{path} is not a template"}
      true ->
        File.rm_rf!(path)
        { :ok, project }
    end
  end
  
  
  def template_path(name) do
    template_dir() |> Path.join(to_string(name))
  end

  @doc """
  Return the template's module, or `nil` if it doesn't exist
  """
  def find(name) do
    path = template_path(name)
    cond do
      is_template?(path) ->
        load_template_module(path)
      true ->
        nil
    end
  end

  @doc """
  Given the path to a project containing a template, load the file 
  in lib/ and return its Module
  """
  def load_template_module(path) do
    with_no_warnings(fn ->
      path
      |> Path.join("lib/*.ex")
      |> Path.wildcard
      |> hd
      |> Code.load_file
      |> hd
      |> elem(0)
    end)
  end

  
  private do
    defp template_dir() do
      Mix.Utils.mix_home |> Path.join("templates")
    end

    defp template_projects() do
      home = template_dir()
      if File.dir?(home) do
        File.ls!(home)
        |> Enum.map(&Path.join([home, &1]))
        |> Enum.filter(&File.dir?/1)
        |> Enum.filter(&is_template?/1)
        |> Enum.map(&load_template_module/1)
      else
        []
      end
    end

    defp is_template?(dir) do
      [ dir, "template" ]
      |> Path.join
      |> File.dir?
    end

    defp with_no_warnings(code) do
      try do
        original_options = Code.compiler_options
        Code.compiler_options(ignore_module_conflict: true)
        result = code.()
        Code.compiler_options(original_options)
        result
      rescue
        _e in _ ->
          nil
      end
    end
  end
  

  @doc """
  remove a template from the cache
  """
  def remove(name) do
    project = [ template_dir(), name ] |> Path.join
    if is_template?(project) do
      File.rm_rf!(project)
      Mix.shell.info("#{name} removed")
    else
      Mix.shell.error("#{name} is not a locally installed template. Use `mix template list` to get a list")
    end
  end
  

    
end
