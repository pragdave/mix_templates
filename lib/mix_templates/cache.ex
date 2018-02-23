defmodule MixTemplates.Cache do
  use Private

  alias MixTemplates.{Docs, Specs}

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
  Format a list of available templates
  """
  def display_list_of_templates() do
    case MixTemplates.Cache.list() do
      [] ->
        Mix.shell().info("""
        No templates installed.

        Use `mix template.hex' to list templates available in hex, and
        `mix template.install` to install the ones you need.
        """)

      list ->
        Mix.shell().info("\nLocally installed templates:\n")
        Enum.each(list, &display_template_info(&1, :short))
    end
  end

  @doc """
  Install a local directory tree into the named slot in the cache.
  """

  def install_from_local_tree(source) do
    if is_template?(source) do
      module = load_template_module(source)
      name = module.name
      target = template_path(name)
      File.mkdir_p!(target)
      File.cp_r!(source, target)
      {:ok, name}
    else
      {:error, "“#{source}” does not contain a valid template"}
    end
  end

  def uninstall_template(project) do
    path = template_path(project)

    cond do
      not is_template?(path) ->
        {:error, "#{path} is not a template"}

      true ->
        File.rm_rf!(path)
        {:ok, project}
    end
  end

  def template_path(name) do
    template_dir() |> Path.join(to_string(name))
  end

  @doc """
  If a template's name starts with a "." or a "/", assume it is a
  local file path, otherwise treat it as a template name
  """
  def find_template(name = <<".", _::binary>>) do
    load_template_module(name)
  end

  def find_template(name = <<"/", _::binary>>) do
    load_template_module(name)
  end

  def find_template(template_name) do
    case find(template_name) do
      nil ->
        error("Cannot find a template called “#{template_name}”")
        Mix.shell().info("\nHere are the available templates:")
        display_list_of_templates()
        exit(:normal)

      module ->
        module
    end
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
      |> Path.wildcard()
      |> hd
      |> Code.load_file()
      |> hd
      |> elem(0)
    end)
  end

  def display_template_info(nil, _) do
    Mix.shell().error([
      "error",
      :reset,
      "unknown template. Use ",
      :green,
      "mix template ",
      :reset,
      "to list locally installed templates and ",
      :green,
      "mix template.hex ",
      :reset,
      "to see them all"
    ])
  end

  def display_template_info(template, :short) do
    Mix.shell().info([:bright, :green, to_string(template.name), :reset, ":"])
    Mix.shell().info("    #{template.short_desc}\n")
  end

  def display_template_info(template, :long) do
    display_template_info(template, :short)
    Docs.module_doc(template)
    display_options(template)
  end

  private do
    defp display_options(template) do
      Specs.accumulate_specs(template, [])
      |> format_specs
    end

    defp format_specs([]), do: nil

    defp format_specs(specs) do
      Mix.shell().info("    Takes the following options:\n")

      specs
      |> Enum.sort()
      |> Enum.each(&format_spec/1)
    end

    defp format_spec({name, options}) do
      takes = format_takes(options)
      flags = format_flags(options)
      description = format_description(options)

      Mix.shell().info([
        :bright,
        :green,
        "\t--#{name}",
        :faint,
        takes,
        "\t",
        :reset,
        :light_blue,
        flags,
        :reset,
        "\n\t    #{description}\n"
      ])
    end

    defp format_flags(options) do
      options
      |> Enum.reduce([], &format_a_flag/2)
      |> Enum.join(", ")
    end

    defp format_a_flag({:default, optvalue}, flags) do
      ["default: #{inspect(optvalue)}" | flags]
    end

    defp format_a_flag({:required, optvalue}, flags)
         when optvalue do
      ["(required)" | flags]
    end

    defp format_a_flag({:same_as, optvalue}, flags) do
      ["(same as: #{optvalue})" | flags]
    end

    defp format_a_flag(_, flags), do: flags

    defp format_takes(options) do
      case options[:takes] do
        nil ->
          ""

        [] ->
          ""

        params when is_binary(params) ->
          " «#{params}»"
      end
    end

    defp format_description(options) do
      case options[:desc] do
        nil -> ""
        desc -> "#{desc}"
      end
    end
  end

  private do
    defp template_dir() do
      Mix.Utils.mix_home() |> Path.join("templates")
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
      [dir, "template"]
      |> Path.join()
      |> File.dir?()
    end

    defp with_no_warnings(code) do
      try do
        original_options = Code.compiler_options()
        Code.compiler_options(ignore_module_conflict: true)
        result = code.()
        Code.compiler_options(original_options)
        result
      rescue
        _e in _ ->
          nil
      end
    end

    defp error(message) do
      Mix.shell().info([:red, "ERROR: ", :reset, message])
    end
  end

  @doc """
  remove a template from the cache
  """
  def remove(name) do
    project = [template_dir(), name] |> Path.join()

    if is_template?(project) do
      File.rm_rf!(project)
      Mix.shell().info("#{name} removed")
    else
      Mix.shell().error(
        "#{name} is not a locally installed template. Use `mix template list` to get a list"
      )
    end
  end
end
