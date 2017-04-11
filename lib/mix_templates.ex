defmodule MixTemplates do

@moduledoc """

> NOTE: This documentation is intended for folks who want to write
> their own templates. If you just want to use a template, then
> have a look at the README, or try `mix help template` and 
> `mix help gen`.


This is the engine that supports templated directory trees.

A template is a trivial mix project. It contains a single source file
in `lib` that contains metadata and option parsing. It also contains a
top-level directory called `template`. The directories and files
underneath `template/` copied to the destination location. 

The copying function tasks a map containing key-value pairs. This is
passed to EEx, which is used to expand each individual file. Thus a
template file for `mix.exs` may contain:

~~~elixir
defmodule <%= @project_name_camel_case %>.Mixfile do
  use Mix.Project

  @name    :<%= @project_name %>
  @version "0.1.0"


The `<%= ... %>` constructs are expanded using the passed-in map.

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

## Write a Template

Make sure you have the underlying tools installed:

    $ mix archive.install hex mix_templates
    $ mix archive.install hex mix_generator

Then install the template for templates (yup :).

    $ mix template.install hex gen_template_template

Now create your template project:

    $ mix gen template my_template

Wander into the directory that is created:

    $ cd my_template/
    $ tree
    .
    ├── README.md
    ├── lib
    │   └── my_template.ex
    ├── mix.exs
    └── template
        └── $PROJECT_NAME$
            └── your_project_tree_goes_here

#### Add a Description

Your first job is to update the metadata in lib/«whatever».ex:

    defmodule MyTemplate do

      @moduledoc File.read!(Path.join([__DIR__, "../README.md"]))

      use MixTemplates,
        name:       :my_template,
        short_desc: "Template for ....",
        source_dir: "../template"

    end

The only change you're likely to make to the metadata is to update the
short description. This is used to display information about the
template when you list the templates you have installed, so you
probably want to keep it under 70 characters.

#### Add the Files

The job of your template is to contain a directory tree that mirrors the
tree you want your users to produce locally when they run `mix gen`.

* The easiest way to start is with an existing project that uses the
  same layout. Copy it into your template under
  `template/$PROJECT_NAME$`.

* Remove any files that aren't part of every project.

* Look for files and directories whose names include the name of the
  project. Rename these, replacing the project name with the string
  $PROJECT_NAME$. For example, if you're following the normal
  convention for test files, you'll have a file called

        test/myapp_test.exs

  Rename this file to

        test/$PROJECT_NAME$.exs
  
* Now you need to look through the files for content that should be
  customized to each new project that's generated. Replace this
  content using EEx substitutions:
  
  For example, the top-level application might be an Elixir file:
  
        defmodule MyApp do
          # . . .
        end
        
  Replace this with
  
        defmodule <%= project_name_camel_case %> do
          # . . .
        end
        
  There's a list of the available values in the next section.
  
### Test Your Template

You can use `mix gen` to test your template while you're developing
it. Simply give it the path to the directory containing the generator
(the top level, with `mix.exs` in it). This path must start with a dot
(".") or slash ("/").

        $ mix gen ../work/my_generator test_project
        
### Publish Your Template

Wander back to the `mix.exs` file at the top of your project, and
update the `@description`, `@maintainers`, and `@github` attributes.
Then publish to hex:

        $ mix hex.publish
        
        
and wait for the praise.

## Standard Substitutions

The following values are available inside EEx substitutions in
templates. (Remember that the inside of a `<%= ...%>` is just Elixir
code, so you aren't limited to this list. The next section describes
how you can extend this set even further in your own templates.)

#### Project Information

Assuming the template was invoked with a project name of my_app:

    @project_name               my_app
    @project_name_camel_case    MyApp


#### Date and Time

These examples are from my computer in US Central Daylight Time
(GMT-5)

    @now.utc.date               "2017-04-11"
    @now.utc.time               "00:49:37.505034"
    @now.utc.datetime           "2017-04-11T00:49:37.505034Z"

    @now.local.date             "2017-04-10"
    @now.local.time             "19:49:37"
    @now.local.datetime         "2017-04-10 19:49:37"


#### The Environment

    @host_os                    "os-name" or "os-name (variant)" eg: "unix (darwin)"
    @original_args              the original args passed to mix
    @elixir_version             eg: "1.5.3"
    @erlang_version             eg: "8.2"
    @otp_release                eg: "19"

#### Stuff About the Template


    @template_module            the module containing your template metadata
    @template_name              the name of the template (from the metadata)

    @target_dir                 where the generated project will go
        

### Handling Command Line Parameters

You may need to configure the output of your template depending on
the options specified on the command line. For example, the standard
`project` template lets you generate basic and supervised apps. To
indicate you want the latter, you add a command line flag:

        $ mix gen project my_app --supervised
        
This option is not handled by the `gen` task. Instead, it passes it to
your template module (the file in your top-level `lib/`). You can
receive the parameters by defining a callback

~~~ elixir
    defmodule MyTemplate do

      @moduledoc File.read!(Path.join([__DIR__, "../README.md"]))

      use MixTemplates,
        name:       :my_template,
        short_desc: "Template for ....",
        source_dir: "../template"

      def populate_assigns(assigns, options) do
        # ...
      end
    end
~~~

The `populate_assigns` function is called immediately after the
standard set of assigns have been created, and before any templating
is done. It receives the current assigns (a map) and the options
passed to `mix gen` (another map). It must return a (potentially
updated) assigns map.

For example, if the user invoked your template with

        $ mix gen a_template my_app --pool 10 --logging

The options passed to `populate_assigns` would be

~~~ elixir
%{into: ".", logging: true, pool: "10"}
~~~

(The `:into` entry is used by the generator—it is basically the target
directory)

You can add these options to your assigns, and then subsequently
use them in your templates.

~~~ elixir
def populate_assigns(assigns, options) do
  assigns
  |> add_assign(options, :pool,     20,   &String.to_integer/1)
  |> add_assign(options, :logging,  false)
end

defp add*assign(assigns, options, option, default, mapper \\ &(&1)) do
  value = Map.get(options, option, default)
  put*in(assigns, option, mapper.(value))
end
~~~

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

  def find(name)
  when is_binary(name) do
    name |> String.to_atom |> find
  end
    
  def find(name) when is_atom(name) do
    IO.inspect "new version"
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


    # You can escape the projrct name by doubling the $ characters,
    # so $$PROJECT_NAME$$ becomes $PROJECT_NAME$
    defp dest_file_name(name, assigns) do
      if name =~ ~r{\$\$PROJECT_NAME\$\$} do
        String.replace(name,"$$PROJECT_NAME$$", "$PROJECT_NAME$")
      else
        String.replace(name, "$PROJECT_NAME$", assigns[:assigns][:project_name])
      end
    end
    
  end  
end
