defmodule MixTemplates.Docs do

  use Private

  def module_doc(module) when is_atom(module) do
    Code.ensure_loaded(module)
    |> look_for_info(module)
  end

  private do
    def look_for_info({:module, _}, module) do
      module
      |> function_exported?(:__info__, 1)
      |> get_docs(module)
    end
    def look_for_info(_, _), do: IO.puts "no info"

    def get_docs(is_elixir?, module) when is_elixir? do
      module
      |> Code.fetch_docs()
      |> extract_module_docs()
      |> format_docs
    end
    def get_docs(_, _), do: IO.puts "no docs"
    
    def extract_module_docs({:docs_v1, _, :elixir, _, %{"en" => module_docs}, _, _}) do
      module_docs
    end

    def format_docs({_, docs}) when is_binary(docs) do
      IO.puts docs
    end
    def format_docs(_), do: nil

  end

end
