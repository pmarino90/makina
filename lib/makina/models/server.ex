defmodule Makina.Models.Server do
  @derive {JSON.Encoder, except: [:password]}
  defstruct host: "", config: %{}, port: 22, user: "", password: nil, __private__: %{}

  @type t() :: %__MODULE__{
          host: String.t(),
          config: map(),
          port: integer(),
          user: String.t(),
          password: String.t(),
          __private__: map()
        }

  @type connected_server() :: %__MODULE__{
          host: String.t(),
          config: map(),
          port: integer(),
          user: String.t(),
          password: String.t(),
          __private__: %{conn_ref: pid()}
        }

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

  def connected?(%__MODULE__{__private__: %{conn_ref: nil}}), do: false

  def connected?(%__MODULE__{__private__: %{conn_ref: conn_ref}}) do
    Process.alive?(conn_ref)
  end

  def connected?(%__MODULE__{__private__: %{}}), do: false
end
