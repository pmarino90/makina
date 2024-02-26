defmodule Makina.Docker do
  @moduledoc """
  Simple wrapper around Docker Engine API
  """

  @docker_socket_path "/Users/paolomarino/.orbstack/run/docker.sock"

  # Container related endpoints

  def list_containers(), do: client() |> Req.get!(url: "/containers/json")

  @doc """
  Creates a container

  `name`: the name to give to the container
  `params`: https://docs.docker.com/engine/api/v1.44/#tag/Container/operation/ContainerCreate

  """
  def create_container(name, %{} = params) do
    client()
    |> Req.post!(
      url: "/containers/create",
      json: params,
      params: [name: name]
    )
  end

  def start_container(name_or_id),
    do:
      client()
      |> Req.post!(url: "/containers/#{name_or_id}/start")

  def attach_container(name_or_id),
    do:
      client()
      |> Req.post!(
        url: "/containers/#{name_or_id}/attach",
        into: IO.stream(),
        params: %{"stream" => true, "stdin" => true, "stdout" => true, "stderr" => true}
      )

  def stop_container(name_or_id),
    do: client() |> Req.post!(url: "/containers/#{name_or_id}/stop")

  def inspect_container(name_or_id),
    do: client() |> Req.get!(url: "/containers/#{name_or_id}/json")

  def wait_for_container(name_or_id),
    do: client() |> Req.post!(url: "/containers/#{name_or_id}/wait")

  def monitor_container(name_or_id, params \\ []) do
    on_event = Keyword.get(params, :on_event, nil)

    client()
    |> Req.Request.append_request_steps(
      debug_url: fn request ->
        IO.inspect(URI.to_string(request.url))
        request
      end
    )
    |> Req.get!(
      url: "/events",
      params: [
        filters:
          Jason.encode!(%{"type" => %{"container" => true}, "container" => %{name_or_id => true}})
      ],
      into: on_event
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
    on_progress = Keyword.get(params, :on_progress, nil)

    client()
    |> Req.post!(
      url: "/images/create",
      headers: params[:headers],
      params: docker_params,
      into: on_progress,
      raw: true
    )
  end

  def list_images(), do: client() |> Req.get!(url: "/images/json", params: [all: true])

  def create_volume(name),
    do: client() |> Req.post!(url: "/volumes/create", json: %{"Name" => name})

  # Service endpoints

  @doc """
  Pings the docker daemon to check if up and running
  """
  def ping(), do: client() |> Req.get!(url: "/_ping")

  defp client(),
    do: Req.new(base_url: "http://localhost/v1.44/", unix_socket: @docker_socket_path)
end
