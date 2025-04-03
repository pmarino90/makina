defmodule Makina.DSL do
  alias Makina.Definitions.Server

  @server_opts [
    host: [type: :string, required: true],
    user: [type: :string],
    password: [type: :string],
    port: [type: :pos_integer, default: 22]
  ]
  def server(opts) do
    opts = NimbleOptions.validate!(opts, @server_opts)
    servers = Map.get(get_config(), :servers, [])

    server = struct(Server, opts)

    get_config()
    |> Map.put(:servers, [server | servers])
    |> put_config()

    server
  end

  defp get_config() do
    Process.get(:makina_config, %{servers: []})
  end

  defp put_config(config) when is_map(config) do
    Process.put(:makina_config, config)
  end
end
