defmodule Makina.Models.Application do
  alias Makina.Models.Internal

  @derive {JSON.Encoder, []}
  defstruct name: nil,
            hash: nil,
            docker_image: nil,
            environment_variables: [],
            volumes: [],
            exposed_ports: []

  def new(opts) do
    app = struct(__MODULE__, opts)
    Map.put(app, :hash, Internal.hash(app))
  end
end
