defmodule Makina.Docker.Behaviour do
  @moduledoc """
  Behaviour representing a generic implementation of a Docker client.

  Mainly mimics and wraps the offical Docker Engine REST API accessible through a UNIX Socket.

  Docker Engine API: https://docs.docker.com/engine/api/v1.44/


  > #### Info {: .info}
  >
  > Most of the functions throw errors, this is done on purpose because as of now the caller
  > has to fail as well if any of these calls fails.
  """

  @type pull_image_param :: {:docker, keyword()} | {:on_progress, nil | IO.Stream.t()}
  @type pull_image_params :: [pull_image_param()]

  # Containers

  @doc """
  Creates a container in the given system.

  Requires a `name`.
  A map of params can be provided in order to futher configure the container.
  Full list of params at: https://docs.docker.com/engine/api/v1.44/#tag/Container/operation/ContainerCreate
  """
  @callback create_container!(String.t(), map()) :: map()

  @callback start_container!(String.t()) :: nil

  @callback stop_container!(String.t()) :: nil

  @callback rename_container!(String.t(), String.t()) :: nil

  @callback remove_container!(String.t()) :: nil

  @callback wait_for_container!(String.t()) :: nil

  @callback logs_for_container!(String.t(), IO.Stream.t() | nil) :: nil

  # Images

  @callback pull_image!(pull_image_params()) :: nil

  @callback inspect_image!(String.t()) :: map()

  # Volumes

  @callback create_volume!(String.t()) :: nil

  # Network

  @callback create_network!(String.t()) :: nil

  @callback connect_network!(String.t(), String.t()) :: nil

  @callback inspect_network(String.t()) :: {:ok, map()} | {:error, Exception.t()}

  # Misc

  @doc """
  Pings the Docker daemon and throws an exception if an error occurres, generally meaning
  the Docker daemon is not running in the host system.
  """
  @callback ping!() :: nil
end
