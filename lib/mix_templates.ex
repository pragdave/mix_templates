defmodule MixTemplates do

@moduledoc """
This is the engine that supports templated directory trees.

A template is a trivial mix project. It contains a single source file
in `lib` that contains metadata and option parsing. It also contains a
top-level directpry called `template`. The directories and files
underneath `template/` copied to the destination location. 

The copying function tasks a map containing key-value pairs. This is
passed to EEx, which is used to expand each individual file. Thus a
template file for `mix.exs` may contain:

~~~elixir
defmodule <%= @project_name_camel_case %>.Mixfile do
  use Mix.Project

  @name    :<%= @project_name %>
  @version "0.1.0"


The `<%= ... %>` constructs are expanded using the passed in map.

In addition, the template looks for the string `$PROJECT_NAME\$` in the
_names_ of files and directories. It replaces each occurrence with the
name of the project, taken from `assigns.project_name`.

Thus the directory structure for a standard Elixir project might be:

    template
    ├── $PROJECT_NAME$
    │   ├── README.md
    │   ├── config
    │   │   └── config.exs
    │   ├── lib
    │   │   └── $PROJECT_NAME$.ex
    │   ├── mix.exs
    │   └── test
    │       ├── $PROJECT_NAME$_test.exs
    │       └── test_helper.exs
    └── templates_project.ex

## Usage

Although MixTemplates provides a programmatic API for finding, listing, and
installing templates, it is normally invoked via mix tasks. The
templates themselves are managed by the `mix template` task.
Generating projects using them is controlled by `mix gen`.

Templates must be installed before use. This is done using the `mix
template` task.

* mix template

  * `mix template [list]`

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

## Installation

    $ mix archive.install hex mix_templates
    $ mix archive.install hex mix_task_gen



"""


  use   Private
  alias Mix.Generator, as: MG
  alias MixTemplates.Cache
  
  defmacro __using__(opts) do
    name = mandatory_option(opts[:name],
      "template must include\n\n\tname: \"template_name\"\n\n")

    override_source_dir = Keyword.get(opts, :source_dir) 
    quote do
      @doc """
      Return the name of this template as an atom. This is
      the name passed to the gen command.
      """
      def name do
        unquote(name)
      end

      @doc """
      Return the short description of this template, or nil.
      """
      def short_desc do
        unquote(opts[:short_desc])
      end

      @doc """
      Return the absolute path to the tree that is to be copied when
      instantiating this template. This top-level dir will typically
      just contain a directory called `$APP_NAME$`.
      """
      def source_dir do
        cond do
          unquote(override_source_dir) ->
            Path.absname(unquote(override_source_dir), __DIR__)
          true ->
            __DIR__
        end
        |> Path.join("$PROJECT_NAME$")
      end

      @doc """
      Override this function to process command line options and 
      set values passed into the template via `assigns`.
      """
      def populate_assigns(assigns, _options) do
        assigns
      end

      defoverridable populate_assigns: 2
    end
  end

  # def known_templates do
  #   :code.all_loaded
  #   |> Enum.map(fn {module, _path} -> module |> Atom.to_string end)
  #   |> Enum.filter(&atom_starts_with(&1, "Elixir.Mix.Gen.Template."))
  #   |> IO.inspect
  #   |> Enum.map(fn module ->
  #     { :module, module } = module |> String.to_atom() |> Code.ensure_loaded()
  #     module
  #   end)
  # end

  def find(name)
  when is_binary(name) do
    name |> String.to_atom |> find
  end
    
  def find(name) do
    Cache.find(name)
  end
  
  def generate(template, assigns = %{ project_name: project_name }) do
    target_dir = assigns.target_dir
    kws = [ assigns: assigns |> Map.to_list ]
    check_existence_of(target_dir, project_name)
    |> create_or_merge(template, kws)
  end

  private do
    
    defp check_existence_of(dir, name) do
      path = Path.join(dir, name)
      cond do
        !File.exists?(dir) ->
          { :error, "target directory #{dir} does not exist" }
        !File.dir?(dir) ->
          { :error, "'#{dir}' is not a directory" }
        !File.exists?(path) ->
          { :need_to_create, path }
        !File.dir?(path) ->
          { :error, "'#{path}' exists but is not a directory" }
        true ->
          { :maybe_update, path }
      end
    end

    defp create_or_merge({:error, reason}, _, _), do: {:error, reason}
    defp create_or_merge({:need_to_create, dest_dir}, template, assigns) do
      source_dir = template.source_dir
      copy_tree_with_expansions(source_dir, dest_dir, assigns)
    end

    defp create_or_merge({:maybe_update, _path}, _, _) do
      { :error, "Updating an existing project is not yet supported" }
    end
    

    defp copy_tree_with_expansions(source, dest, assigns) do
      if File.dir?(source) do
        if !String.ends_with?(source, "_build") do
          copy_dir(source, dest, assigns)
        end
      else
        copy_and_expand(source, dest, assigns)
      end
    end

    defp copy_dir(source, dest, assigns) do
      MG.create_directory(dest)
      File.ls!(source)
      |> Enum.each(fn name ->
        s = Path.join(source, name)
        d = Path.join(dest, dest_file_name(name, assigns))
        copy_tree_with_expansions(s, d, assigns)
      end)
    end

    defp copy_and_expand(source, dest, assigns) do
      content = EEx.eval_file(source, assigns)
      MG.create_file(dest, content)
      mode = File.stat!(source).mode
      File.chmod!(dest, mode)
    end

    defp mandatory_option(nil,    msg), do: raise(CompileError, description: msg)
    defp mandatory_option(value, _msg), do: value

   
    defp dest_file_name(name, assigns) do
      String.replace(name, "$PROJECT_NAME$", assigns[:assigns][:project_name])
    end
    
  end  
end
