defmodule Mix.Tasks.Template.Hex do
  use Private

  @moduledoc Path.join([__DIR__, "../../../README.md"])
             |> File.read!()
             |> String.replace(~r/\A.*^### Use\w+/ms, "")
             |> String.replace(~r/^###.*/ms, "")

  def run(_) do
    Mix.Hex.start()

    "gen_template"
    |> search()
    |> extract_stuff_we_need()
    |> display_results()
  end

  private do
    defp extract_stuff_we_need({:ok, response}) do
      extract_stuff_we_need(response)
    end

    defp extract_stuff_we_need({:error, term}) do
      Mix.raise("error #{inspect(term)} while searching hex packages")
    end

    defp extract_stuff_we_need({200, content, _}) do
      content
      |> Enum.filter(&is_a_template?/1)
    end

    defp extract_stuff_we_need({error, _, _}) do
      Mix.raise("error #{error} while searching hex packages")
    end

    defp is_a_template?(%{"name" => name}) do
      name |> String.starts_with?("gen_template_")
    end

    defp display_results([]) do
      Mix.shell().info("Strange... no templates found on hex.pm")
    end

    defp display_results(results) do
      Mix.shell().info(["\n", :underline, "Templates on hex.pm", :reset, "\n"])
      results |> Enum.each(&display_a_result/1)
      Mix.shell().info("Install a template using `mix template.install «name»`\n")
    end

    defp display_a_result(%{
           "name" => name,
           "meta" => %{
             "description" => description
           }
         }) do
      Mix.shell().info([:bright, :green, name, :reset, ":\n", indent(description)])
    end

    defp indent(string) do
      "    #{String.replace(string, "\n", "\n    ") |> String.trim_trailing()}\n"
    end

    # hex changed the internal API in fall 2017, so we have to deal with both

    require Hex.API.Package

    cond do
      function_exported?(Hex.API.Package, :search, 1) ->
        defdelegate search(package), to: Hex.API.Package

      function_exported?(Hex.API.Package, :search, 2) ->
        defp search(package) do
          url = Hex.State.fetch!(:api_url) <> "/"
          Hex.API.Package.search(nil, package)
        end

      true ->
        raise "Can't find Hex.API.Package.search/1 or /2"
    end
  end
end
