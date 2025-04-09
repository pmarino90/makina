defmodule Makina.Models.Application do
  @doc """
  Represents an application as describe in a Makinafile.

  ## About the hash
  When the structure is created and updated an internal hash is computed.
  This is used to track changes between a instance of the app in a given Makinafile and
  possible a previous instance.
  The hash is added as label to the running container and can be used to understand
  whether a running application has to be updated or not.

  For example:
  * `T0` - We have an app that deploys nginx with tag `1.26`, we deploy that to the remote
  server;
  * `T1` - We update the Makinafile and change tag from `1.26` to `1.27`. When we launch
  a deployment Makina will know that this app changed and therefore it will be updated;


  ## Internal fields
  Given that this structure is almost never exposed to the end user one could see it as
  part of the public API nonetheless.
  Ideally the aim is to try to keep that consistent and not break it over time.

  However there are "private" fields which are used in multiple cases by the system that
  are subject to changes and should never be relied on.
  These are:
  * `:__hash__` which is the hash of all properties (except the private ones)
  * `:__docker__` specific internal configurations used for docker that are not (yet)
  * `:__scope__` collects nesting levels in the makina file in order to reliably distinguish apps
  exposed to the DSL.
  """

  alias Makina.Models.Internal

  @hashable_keys ~w[name docker_image docker_registry env_vars volumes exposed_ports]a

  @derive {JSON.Encoder, []}
  defstruct __hash__: nil,
            __docker__: %{
              labels: [],
              command: []
            },
            __scope__: [],
            name: nil,
            docker_image: nil,
            docker_registry: nil,
            volumes: [],
            env_vars: [],
            exposed_ports: []

  def new(opts) do
    app = struct(__MODULE__, opts)
    current_hash = hash(app)

    app
    |> set_private(:__hash__, current_hash)
  end

  def put_volume(%__MODULE__{} = app, volume) when is_list(volume) do
    volume = Enum.into(volume, %{})
    app = %__MODULE__{app | volumes: [volume | app.volumes]}

    set_private(app, :__hash__, hash(app))
  end

  def put_environment(%__MODULE__{} = app, env) when is_list(env) do
    env = Enum.into(env, %{})
    app = %__MODULE__{app | env_vars: [env | app.env_vars]}

    set_private(app, :__hash__, hash(app))
  end

  def put_exposed_port(%__MODULE__{} = app, port) when is_list(port) do
    port = Enum.into(port, %{})
    app = %__MODULE__{app | exposed_ports: [port | app.exposed_ports]}

    set_private(app, :__hash__, hash(app))
  end

  def set_docker_image(%__MODULE__{} = app, image) when is_list(image) do
    image = image |> Enum.into(%{})
    app = %__MODULE__{app | docker_image: image}

    set_private(app, :__hash__, hash(app))
  end

  def set_docker_registry(%__MODULE__{} = app, registry) when is_list(registry) do
    registry = registry |> Enum.into(%{})
    app = %__MODULE__{app | docker_registry: registry}

    set_private(app, :__hash__, hash(app))
  end

  def private_docker_registry?(%__MODULE__{docker_registry: nil}) do
    false
  end

  def private_docker_registry?(%__MODULE__{docker_registry: docker_registry}) do
    not (is_nil(docker_registry.user) and is_nil(docker_registry.password))
  end

  def set_private(%__MODULE{} = app, key, value) do
    app |> Map.put(key, value)
  end

  defp hash(%__MODULE__{} = app) do
    keys = @hashable_keys |> Enum.sort()
    fields = keys |> Enum.map(&Map.get(app, &1))

    Internal.hash(fields)
  end
end
