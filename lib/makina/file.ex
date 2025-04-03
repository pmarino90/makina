defmodule Makina.File do
  alias Makina.Definitions.Server

  def compile_build_file(path) do
    {_term, bindings} = Code.eval_file(path)

    bindings
  end

  def fetch_servers(bindings) do
    bindings
    |> Keyword.values()
    |> Enum.filter(&is_struct(&1, Server))
  end
end
