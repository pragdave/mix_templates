defmodule Mix.Tasks.Template.Install do

  @moduledoc(
    Path.join([__DIR__, "../../../README.md"])
    |> File.read!
    |> String.replace(~r/\A.*^### Use\s+/ms, "")
    |> String.replace(~r/^###.*/ms, ""))


  
  defmodule TargetTemplate do

    @moduledoc """
    Define naming conventions for template targets
    """
    
    @behaviour Mix.Local.Target

    def name_for(project) do
      project[:app]
      |> to_string()
    end
    
    def path_for() do
      Path.join(Mix.Utils.mix_home, "templates")
    end
    
    def printable_name() do
      { "template", "templates" }
    end
    
    def task_name(), do: "template"
  end
  

  use    Private
  use    Mix.Task
  alias  MixTemplates.Cache


  @doc nil
  @spec run(OptionParser.argv) :: boolean  
  def run(argv) do
    install(argv, [])
  end

  
  
  def install(argv, switches) do
    {opts, args} = OptionParser.parse!(argv, strict: switches)
    target = TargetTemplate

    install_spec =
      case parse_args(args, opts) do
        {:error, message} -> Mix.raise message <> "\n" <> usage()
        install_spec      -> install_spec
      end

    case check_install_spec(install_spec, opts) do
      :ok               -> :noop
      {:error, message} -> Mix.raise message <> "\n" <> usage()
    end

    case install_spec do
      {:fetcher, dep_spec} ->
        if opts[:sha512] do
          Mix.raise "--sha512 is not supported for template.install from git/github/hex\n" <> usage()
        end

        fetch dep_spec, fn mixfile ->
          build(mixfile)
          argv = if opts[:force], do: ["--force"], else: []
          install(argv, switches)
        end

      {:local, src} ->
        install_from_local(src)

      {:url, src} ->
        do_install(target, src, opts)
        
      :project ->
        install_from_local(System.cwd())
    end
  end

  defp install_from_local(src) do
    case Cache.install_from_local_tree(src) do
      { :error, reason } ->
        Mix.raise(reason)
      { :ok, template_name } ->
        Mix.shell.info(["template ",
                        :green, "#{template_name}",
                        :reset, " installed successfully"])
        :ok
    end
  end
  
  defp local_dir?(url_or_path) do
    File.dir?(url_or_path)
  end

  defp file_url?(url_or_path) do
    URI.parse(url_or_path).scheme in ["http", "https"]
  end

  @doc """
  Checks that the `install_spec` and `opts` are supported
  """
  def check_install_spec(_, _) do
    :ok
  end
  

  @doc """
  Returns a list of already installed version of the same archive or escript.
  """
  def find_previous_versions(_src, dst) do
    if File.exists?(dst), do: [dst], else: []
  end

  @doc """
  For installs involving a `fetch`, this will be executed as the `in_package`.
  """
  def build(_) do
    IO.puts "Project contains: #{inspect Path.wildcard("*")}"
  end
  
  defp usage() do
    "\nRun:\n\n    mix help template.install\n\nfor more information."
  end

  defp do_install(name, src, opts) do
    src_basename   = Path.basename(URI.parse(src).path)
    dst            = Path.join(Mix.Local.path_for(name), src_basename)
    previous_files = find_previous_versions(src, dst)

    if opts[:force] || should_install?(name, src, previous_files) do
      case Mix.Utils.read_path(src, opts) do
        {:ok, _binary} ->
          # install(dst, binary, previous_files)
          :ok
          
        :badpath ->
          Mix.raise "Expected #{inspect src} to be a URL or a local file path"

        {:local, message} ->
          Mix.raise message

        {kind, message} when kind in [:remote, :checksum] ->
          Mix.raise """
          #{message}

          Could not fetch #{name} at:

              #{src}

          Please download the #{name} above manually to your current directory and run:

              mix #{name}.install ./#{src_basename}
          """
      end

      true
    else
      false
    end
  end

  defp should_install?(name, src, previous_files) do
    message = case previous_files do
      [] ->
        "Are you sure you want to install #{name} #{inspect src}?"
      [file] ->
        "Found existing #{name}: #{file}.\n" <>
        "Are you sure you want to replace it with #{inspect src}?"
      files ->
        "Found existing #{name}s: #{Enum.map_join(files, ", ", &Path.basename/1)}.\n" <>
        "Are you sure you want to replace them with #{inspect src}?"
    end
    Mix.shell.yes?(message)
  end

  @doc """
  Receives `argv` and `opts` from options parsing and returns an `install_spec`.
  """
  def parse_args(argv, opts)

  def parse_args([], _opts) do
    :project
  end

  def parse_args([url_or_path], _opts) do
    cond do
      local_dir?(url_or_path) -> {:local, url_or_path}
      file_url?(url_or_path)  -> {:url, url_or_path}
      true -> {:error, "Expected a local file path or a file URL."}
    end
  end

  def parse_args(["github" | rest], opts) do
    [repo | rest] = rest
    url = "https://github.com/#{repo}.git"
    parse_args(["git", url] ++ rest, opts)
  end

  def parse_args(["git", url], opts) do
    parse_args(["git", url, "branch", "master"], opts)
  end

  def parse_args(["git", url, ref_type, ref], opts) do
    case ref_to_config(ref_type, ref) do
      {:error, error} ->
        {:error, error}

      git_config ->
        git_opts = git_config ++ [git: url, submodules: opts[:submodules]]
        app_name =
          if opts[:app] do
            opts[:app]
          else
            "new package"
          end

        {:fetcher, {String.to_atom(app_name), git_opts}}
    end
  end

  def parse_args(["git" | [_url | rest]], _opts) do
    {:error, "received invalid git checkout spec: #{Enum.join(rest, " ")}"}
  end

  def parse_args(["hex", package_name], opts) do
    parse_args(["hex", package_name, ">= 0.0.0"], opts)
  end

  def parse_args(["hex", package_name, version], opts) do
    app_name =
      if opts[:app] do
        opts[:app]
      else
        package_name
      end

    {:fetcher, {String.to_atom(app_name), version, hex: String.to_atom(package_name)}}
  end

  def parse_args(["hex" | [_package_name | rest]], _opts) do
    {:error, "received invalid Hex package spec: #{Enum.join(rest, " ")}"}
  end

  defp ref_to_config("branch", branch), do: [branch: branch]

  defp ref_to_config("tag", tag), do: [tag: tag]

  defp ref_to_config("ref", ref), do: [ref: ref]

  defp ref_to_config(ref_type, _) do
    {:error, "expected one of \"branch\", \"tag\", or \"ref\". Got: \"#{ref_type}\""}
  end

  @doc """
  Prints a list of items in a uniform way. Used for printing the list
  of installed archives, escripts, and so on. The first parameter is
  the Mix.Local.Target module of the type of items.
  """
  @spec print_list(atom, [String.t]) :: :ok
  def print_list(target, []) do
    {_name, names} = target.printable_name()
    Mix.shell.info "No #{names} currently installed."
  end

  def print_list(target, items) do
    {_name, names} = target.printable_name()
    Enum.each items, fn item -> Mix.shell.info ["* ", item] end
    item_names = String.capitalize(names)
    Mix.shell.info "#{item_names} installed at: #{Mix.Local.path_for(target)}"
  end

  @doc """
  A common implementation for uninstalling archives and scripts.
  """
  @spec uninstall(atom, OptionParser.argv) :: boolean
  def uninstall(target, argv) do
    {_, argv, _} = OptionParser.parse(argv)

    { item_name, item_names } = target.printable_name()

    root = Mix.Local.path_for(target)

    if name = List.first(argv) do
      path = Path.join(root, name)
      cond do
        not File.exists?(path) ->
          Mix.shell.error("Could not find a local #{item_name} named #{inspect name}.")
          Mix.shell.info("Existing #{item_names} are:")
          Mix.Task.run item_name
          nil
        should_uninstall?(path, item_name) ->
          File.rm_rf!(path)
          path
        true ->
          nil
      end
    else
      Mix.raise "No #{item_name} was given to #{item_name}.uninstall"
    end
  end

  defp should_uninstall?(path, item_name) do
    Mix.shell.yes?("Are you sure you want to uninstall #{item_name} #{path}?")
  end

  @doc """
  Fetches `dep_spec` with `in_fetcher` and then runs `in_package`.

  Generates a new mix project in a temporary directory with the given `dep_spec`
  added to a mix.exs. Then, `in_fetcher` is executed in the fetcher project. By
  default, this fetches the dependency, but you can provide an `in_fetcher`
  during test or for other purposes. After the `in_fetcher` is executed,
  `in_package` is executed in the now (presumably) fetched package, with the
  package's config overridden with the deps_path and lockfile of the fetcher
  package. Also, the Mix env is set to :prod.
  """
  @spec fetch(tuple, ((atom) -> any), ((atom) -> any)) :: any
  def fetch(dep_spec, in_fetcher \\ &in_fetcher/1, in_package) do
    with_tmp_dir fn tmp_path ->
      File.mkdir_p!(tmp_path)

      File.write! Path.join(tmp_path, "mix.exs"), """
      defmodule Mix.Local.Installer.Fetcher.Mixfile do
        use Mix.Project

        def project do
          [app: Mix.Local.Installer.Fetcher,
           version: "1.0.0",
           deps: [#{inspect dep_spec}]]
        end
      end
      """

      with_mix_env_prod fn ->
        Mix.Project.in_project(Mix.Local.Installer.Fetcher, tmp_path, in_fetcher)

        package_name = elem(dep_spec, 0)
        package_name_string = Atom.to_string(package_name)
        package_path = Path.join([tmp_path, "deps", package_name_string])
        post_config = [
          deps_path: Path.join(tmp_path, "deps"),
          lockfile: Path.join(tmp_path, "mix.lock")
        ]

        Mix.Project.in_project(package_name, package_path, post_config, in_package)
      end
    end
  after
    :code.purge(Mix.Local.Installer.Fetcher)
    :code.delete(Mix.Local.Installer.Fetcher)
  end

  defp in_fetcher(_mixfile) do
    Mix.Task.run("deps.get", [])
  end

  defp with_tmp_dir(fun) do
    unique = :crypto.strong_rand_bytes(4) |> Base.url_encode64(padding: false)
    tmp_path = Path.join(System.tmp_dir!(), "mix-local-installer-fetcher-" <> unique)

    try do
      fun.(tmp_path)
    after
      File.rm_rf(tmp_path)
    end
  end

  defp with_mix_env_prod(fun) do
    previous_env = Mix.env()

    try do
      Mix.env(:prod)
      fun.()
    after
      Mix.env(previous_env)
    end
  end
end

