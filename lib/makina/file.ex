defmodule Makina.File do
  def compile_build_file(path) do
    file = File.read!(path)
    {:ok, env} = Macro.Env.define_import(__ENV__, [line: 1], Makina.DSL)
    {_term, bindings} = Code.eval_string(file, [], env)

    bindings
  end

  def fetch_servers() do
    Process.get(:makina_config, %{servers: []})
    |> Map.get(:servers)
    |> Enum.reverse()
  end
end
