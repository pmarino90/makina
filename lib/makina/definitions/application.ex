defmodule Makina.Definitions.Application do
  @derive {JSON.Encoder, []}
  defstruct docker_image: nil, environment_variables: [], volumes: [], exposed_ports: []
end
