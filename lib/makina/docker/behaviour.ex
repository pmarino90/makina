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

  @doc """
  Starts a container give it's name or ID
  """
  @callback start_container!(String.t()) :: nil

  @doc """
  Stops a running container given its name or ID.
  """
  @callback stop_container!(String.t()) :: nil

  @callback rename_container!(String.t(), String.t()) :: nil

  @callback remove_container!(String.t()) :: nil

  @callback wait_for_container!(String.t()) :: nil

  @callback logs_for_container!(String.t(), IO.Stream.t() | nil) :: nil

  # Images

  @doc """
  Create an image

  Accepts the following `params`:
  * `docker` map of options for the Docker Engine API,
  see: https://docs.docker.com/engine/api/v1.44/#tag/Image/operation/ImageCreate
  * `on_progress` an iterate into which pushing the progress while the operation is in progress.
  """
  @doc section: :images
  @callback create_image(pull_image_params()) ::
              {:ok, Req.Response.t()} | {:error, Req.Response.t()}

  @doc """
  Returns all the information from Docker Engine of the given image
  """
  @doc section: :images
  # Volumes
  @callback inspect_image!(String.t()) :: Req.Response.t()
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
  @callback ping() :: {:ok, Req.Response.t()} | {:error, Req.Response.t()}
end
