defmodule Makina.Docker do
  @moduledoc """
  Simple wrapper around Docker Engine API
  """

  @docker_socket_path "/Users/paolomarino/.orbstack/run/docker.sock"

  # Container related endpoints

  def list_containers(), do: client() |> Req.get!(url: "/containers/json")

  @doc """
  Creates and runs a container

  `name`: the name to give to the container
  `params`: https://docs.docker.com/engine/api/v1.44/#tag/Container/operation/ContainerCreate

  """
  def create_container(name, %{} = params) do
    client()
    |> Req.post!(
      url: "/v1.44/containers/create",
      json: params,
      params: [name: name]
    )
  end

  # Images related endpoints

  @doc """
  Pulls an image from a registry

  `params.on_progress`: function called with the current pull progress
  `params.docker` -> https://docs.docker.com/engine/api/v1.44/#tag/Image/operation/ImageCreate
  """
  def pull_image(params) when is_list(params) do
    docker_params = Keyword.get(params, :docker)
    on_progress = Keyword.get(params, :on_progress, fn -> nil end)

    client()
    |> Req.post!(
      url: "/images/create",
      params: docker_params,
      into: on_progress
    )
  end

  def list_images(), do: client() |> Req.get!(url: "/images/json", params: [all: true])

  # Service endpoints

  @doc """
  Pings the docker daemon to check if up and running
  """
  def ping(), do: client() |> Req.get!(url: "/_ping")

  defp client(),
    do: Req.new(base_url: "http://localhost/v1.44/", unix_socket: @docker_socket_path)
end
