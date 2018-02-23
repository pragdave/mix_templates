defmodule MixTemplates do
  @moduledoc ~S"""

  > NOTE: This documentation is intended for folks who want to write
  > their own templates. If you just want to use a template, then
  > have a look at the README, or try `mix help template` and
  > `mix help gen`.


  This is the engine that supports templated directory trees.

  A template is a trivial mix project that acts as the specification for
  the projects you want your users to be able to generate. It contains a
  single source file in `lib` that contains metadata and option parsing.
  It also contains a top-level directory called `template`. The
  directories and files underneath `template/` copied to the destination
  location.

  The copying function takes a map containing key-value pairs. This is
  passed to EEx, which is used to expand each individual file. Thus a
  template file for `mix.exs` may contain:

  ~~~elixir
  defmodule <%= @project_name_camel_case %>.Mixfile do
    use Mix.Project

    @name    :<%= @project_name %>
    @version "0.1.0"

    . . .
  ~~~


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
          source_dir: "../template",
          based_on:   :another_project,
          options:    [ command line options unique to this template ]

      end

  For a simple template, the only change you're likely to make to the
  metadata is to update the short description. This is used to display
  information about the template when you list the templates you have
  installed, so you probably want to keep it under 70 characters.

  If you want to write a template that is based on another, use the
  `:based_on` option. This causes the parent template to be processed
  before your local template. This means your template need only implement
  the changes to the base.

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

      @in_umbrella?               true if we're in the apps_path directory of an
                                  umbrella project

  #### Stuff About the Template


      @template_module            the module containing your template metadata
      @template_name              the name of the template (from the metadata)

      @target_dir                 the project directory is created in this
      @target_subdir              the project directory is called this


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
      options:    [
          supervised: [ to: :is_supervised?, default: false ],
          sup:        [ same_as: :supervised ],
      ]
  end
  ~~~

  `options` is a specification of the command line parameters that your
  template accepts. In all cases, the key is the parameter as it appears
  on the command line, and the keyword list that is the value gives
  information about that option.

  The simplest option is

  ~~~ elixir
  name:  []
  ~~~

  This says that `--name` is a valid option. If you add it to the
  command line with no value following it, then `:name` will appear in
  the assigns with the value `true`. It you pass in a value, then that
  value will appear in the assigns.project_name

  If you do not specify `--name` on the command line, there will be no
  entry with the key `:name` in the assigns.

  If your option takes an argument, you specify its name using `takes:`.

  ~~~ elixir
  name:  [ takes: "your-name" ]
  ~~~


  The `required` key says that a given parameter _must_ appear on the command line.

  ~~~ elixir
  name:  [
    takes:    "your-name",
    required: true
  ]
  ~~~

  `default` provides a value to use if the parameter does not appear on
  the command line:

  ~~~ elixir
  name:  [
    takes:   "your-name",
    default: "nancy"
  ]
  ~~~

  If a default value is given, the entry will _always_ appear in the
  assigns.project_name

  By default the name of the field in the assigns will be the key in the
  options list. You can override this using `to`.

  ~~~ elixir
  name:  [
    takes:   "your-name",
    to:      :basic_id,
    default: "nancy"
  ]
  ~~~

  In this example, calling

       $ mix gen my_template my_app --name walter

  will create an assigns map that includes `\@basic_id` with a value of “walter.”

  Finally, you can alias a option using `same_as`.

  The following will allow both `--sup` and `--supervised` on the
  command line, and will map either to the key `:is_supervised?` in the
  assigns.

  ~~~ elixir
  options:    [
      supervised: [ to: :is_supervised?, default: false ],
      sup:        [ same_as: :supervised ],
  ]
  ~~~



  ### Dealing with optional files and directories

  Sometimes you need to include a file or directory only if some condition
  is true. Use these helpers:

  * `MixTemplates.ignore_file_and_directory_unless(«condition»)`

    Include this in a template, and the template and it's immediate directory
    will not be generated in the output unless the condition is true.

    For example, in a new mix project, we only generate
    `lib/«name»/application.ex` if we're creating a supervised app. The
    `application.ex` template includes the following:

      ~~~ elixir
      <%
      #   ------------------------------------------------------------
          MixTemplates.ignore_file_and_directory_unless \@is_supervisor?
      #   ------------------------------------------------------------
      %>
      defmodule <%= \@project_name_camel_case %>.Application do
         # ...
      end
      ~~~

  Sometimes you just need to skip a single file if some condition is true. Use this helper:

  * `MixTemplates.ignore_file_unless(«condition»)`

  ### Cleaning Up

  In most cases your work is done once the template is copied into the
  project. There are times, however, where you may want to do some
  manual adjustments at the end. For that, add a `clean_up/1` function
  to your template module.

  ~~~ elixir
  def clean_up(assigns) do
    # ...
  end
  ~~~

  The cleanup function is invoked in the directory where the project is
  created (and not inside the project itself). Thus if you invoke

      mix gen my_template chat_server

  in the directory `/Projects` (which will create
  `/Projects/chat_server`), the `clean_up` function's cwd will be
  `/Projects`.


  ### Deriving from Another Template

  Sometimes you want to create a template which is similar to another. Perhaps
  some files' contents are different, new files are added or others taken away.

  Use the `based_on: «template»` option to facilitate this:

  ~~~ elixir
  defmodule MyTemplate do

    \@moduledoc File.read!(Path.join([__DIR__, "../README.md"]))

    use MixTemplates,
      name:       :my_template,
      short_desc: "Template for ....",
      source_dir: "../template",
      based_on:   :project

    def populate_assigns(assigns, options) do
      # ...
    end
  end
  ~~~

  The value of `based_on` is the name or the path to a template.

  When people create a project based on your template, the generator
  will run twice. The first time, it creates the `based_on` project. It
  then runs again with your template. Any files or directories in your
  template will overwrite the corresponding files in the based-on
  template.

  It isn't necessary to have a full tree under the `template` directory
  in your template. Just populate the parts you want to override in the
  base template.

  If you want to remove files generated by the base template, you can
  add code to the `clean_up/1` hook. Remember that the cleanup hook is
  invoked in the directory that contains the target project, so you'll
  need to descend down into the project itself. Obviously, this is
  something you'll want to test carefully before releasing :)

  ~~~ elixir
  def clean_up(assigns) do
    Path.join([assigns.target_subdir, "lib", "#{assigns.project_name}.ex"]))
    |>  File.rm
  end
  ~~~

  """

  use Private
  alias Mix.Generator, as: MG
  alias MixTemplates.Cache

  defmacro __using__(opts) do
    name = mandatory_option(opts[:name], "template must include\n\n\tname: \"template_name\"\n\n")

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
      Return the name or path of a template that this template is
      based upon. That template will be processed first, and then
      this one will be executed.
      """
      def based_on do
        unquote(opts[:based_on])
      end

      @doc """
      Return the list of options supported by this template.
      """
      def options do
        unquote(opts[:options] || [])
      end

      @doc """
      Override this function to do any cleanup after your template
      has been copied into the user project. One use of this is to remove
      unwanted files created by a template upon which this template
      is based.
      """
      def clean_up(_assigns) do
        nil
      end

      defoverridable clean_up: 1
    end
  end

  def find(name)
      when is_binary(name) do
    name |> String.to_atom() |> find
  end

  def find(name) when is_atom(name) do
    Cache.find(name)
  end

  def generate(template, assigns) do
    kws = [assigns: assigns |> Map.to_list()]

    check_existence_of(assigns.target_dir, assigns.target_subdir)
    |> create_or_merge(template, kws)
  end

  # called from within a template to cause it not to generate either this
  # file or anything in this file's directory

  def ignore_file_and_directory_unless(flag) when flag do
    # bypass unused variable warning
    flag && nil
  end

  def ignore_file_and_directory_unless(_) do
    throw(:ignore_file_and_directory)
  end

  # called from within a template to cause it not to generate this file

  def ignore_file_unless(flag) when flag do
    # bypass unused variable warning
    flag && nil
  end

  def ignore_file_unless(_) do
    throw(:ignore_file)
  end

  private do
    defp check_existence_of(dir, name) do
      path = Path.join(dir, name)

      cond do
        !File.exists?(dir) ->
          {:error, "target directory #{dir} does not exist"}

        !File.dir?(dir) ->
          {:error, "'#{dir}' is not a directory"}

        !File.exists?(path) ->
          {:need_to_create, path}

        !File.dir?(path) ->
          {:error, "'#{path}' exists but is not a directory"}

        true ->
          {:maybe_update, path}
      end
    end

    defp create_or_merge({:error, reason}, _, _), do: {:error, reason}

    defp create_or_merge({:need_to_create, dest_dir}, template, assigns) do
      source_dir = template.source_dir
      copy_tree_with_expansions(source_dir, dest_dir, assigns)
    end

    defp create_or_merge({:maybe_update, dest}, template, assigns) do
      if assigns[:assigns][:force] do
        copy_tree_with_expansions(template.source_dir, dest, assigns)
      else
        {:error, "Updating an existing project is not yet supported"}
      end
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
      maybe_create_directory(dest, assigns[:assigns][:force])

      try do
        File.ls!(source)
        |> Enum.each(fn name ->
          s = Path.join(source, name)
          d = Path.join(dest, dest_file_name(name, assigns))
          copy_tree_with_expansions(s, d, assigns)
        end)
      catch
        :ignore_file_and_directory ->
          File.rm_rf!(dest)

          Mix.shell().info([
            :green,
            "- deleting",
            :reset,
            " #{dest} ",
            :faint,
            :cyan,
            "(it isn't needed)"
          ])
      end
    end

    defp copy_and_expand(source, dest, assigns) do
      try do
        content = EEx.eval_file(source, assigns, trim: true)
        MG.create_file(dest, content)
        mode = File.stat!(source).mode
        File.chmod!(dest, mode)
      catch
        :ignore_file ->
          Mix.shell().info([
            :green,
            "- ignoring",
            :reset,
            " #{dest} ",
            :faint,
            :cyan,
            "(it isn't needed)"
          ])
      end
    end

    defp mandatory_option(nil, msg), do: raise(CompileError, description: msg)
    defp mandatory_option(value, _msg), do: value

    # You can escape the projrct name by doubling the $ characters,
    # so $$PROJECT_NAME$$ becomes $PROJECT_NAME$
    defp dest_file_name(name, assigns) do
      if name =~ ~r{\$\$PROJECT_NAME\$\$} do
        String.replace(name, "$$PROJECT_NAME$$", "$PROJECT_NAME$")
      else
        String.replace(name, "$PROJECT_NAME$", assigns[:assigns][:project_name])
      end
    end

    defp maybe_create_directory(path, force) when not force do
      MG.create_directory(path)
    end

    defp maybe_create_directory(path, _force) do
      if File.exists?(path) do
        Mix.shell().info([:green, "• existing #{path}"])
      else
        maybe_create_directory(path, false)
      end
    end
  end
end
