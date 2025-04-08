defmodule Makina.Models.Server do
  @derive {JSON.Encoder, except: [:password]}
  defstruct host: "", config: %{}, port: 22, user: "", password: nil, __private__: %{}

  def new(opts) do
    struct(__MODULE__, opts)
  end

  def put_config(%__MODULE__{} = server, config) do
    config = config |> Enum.into(%{}) |> Map.merge(server.config)

    %__MODULE__{server | config: config}
  end

  def set_port(%__MODULE__{} = server, port) do
    %__MODULE__{server | port: port}
  end

  def set_user(%__MODULE__{} = server, user) do
    %__MODULE__{server | user: user}
  end

  def set_password(%__MODULE__{} = server, password) do
    %__MODULE__{server | password: password}
  end

  def put_private(%__MODULE__{} = server, key, value) do
    private = Map.put(server.__private__, key, value)

    %__MODULE__{server | __private__: private}
  end
end
