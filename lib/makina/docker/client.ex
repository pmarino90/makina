defmodule Makina.Docker.Client do
  @behaviour Makina.Docker.Behaviour

  @moduledoc """
  Simple wrapper around Docker Engine API
  """

  # Container related endpoints
  @impl true
  def create_container!(name, %{} = params) do
    client()
    |> Req.post!(
      url: "/containers/create",
      json: params,
      params: [name: name]
    )
  end

  @impl true
  def start_container!(name_or_id),
    do:
      client()
      |> Req.post!(url: "/containers/#{name_or_id}/start")
      |> as_nil()

  @impl true
  def stop_container!(name_or_id),
    do:
      client()
      |> Req.post!(url: "/containers/#{name_or_id}/stop")
      |> as_nil()

  @impl true
  def rename_container!(name_or_id, new_name),
    do:
      client()
      |> Req.post!(url: "/containers/#{name_or_id}/rename", params: %{"name" => new_name})
      |> as_nil()

  @impl true
  def remove_container!(name_or_id),
    do:
      client()
      |> Req.delete!(url: "/containers/#{name_or_id}", params: %{"v" => true})
      |> as_nil()

  @impl true
  def wait_for_container!(name_or_id),
    do:
      client()
      |> Req.post!(url: "/containers/#{name_or_id}/wait")
      |> as_nil()

  @impl true
  def logs_for_container!(name_or_id, into \\ nil),
    do:
      client()
      |> Req.get!(
        url: "/containers/#{name_or_id}/logs",
        params: %{"follow" => true, "stderr" => true, "stdout" => true},
        into: into
      )
      |> as_nil()

  @impl true
  def create_image(params) when is_list(params) do
    docker_params = Keyword.get(params, :docker)
    on_progress = Keyword.get(params, :on_progress, nil)

    client()
    |> Req.post(
      url: "/images/create",
      headers: params[:headers] || [],
      params: docker_params,
      into: on_progress,
      raw: true
    )
  end

  @impl true
  def inspect_image(name_or_id), do: client() |> Req.get(url: "/images/#{name_or_id}/json")

  @impl true
  def create_volume!(name),
    do:
      client()
      |> Req.post!(url: "/volumes/create", json: %{"Name" => name})
      |> as_nil()

  @impl true
  def create_network!(name),
    do:
      client()
      |> Req.post!(
        url: "/networks/create",
        json: %{"Name" => name, "Driver" => "bridge", "Attachable" => true, "Internal" => true}
      )
      |> as_nil()

  @impl true
  def inspect_network(name), do: client() |> Req.get(url: "/networks/#{name}")

  @impl true
  def connect_network!(container, network),
    do:
      client()
      |> Req.post!(url: "/networks/#{network}/connect", json: %{"Container" => container})
      |> as_nil()

  # Service endpoints

  @impl true
  def ping(), do: client() |> Req.get(url: "/_ping")

  defp client() do
    config = Application.get_env(:makina, Makina.Docker, [])

    Req.new(
      base_url: "http://localhost/v1.44/",
      unix_socket: Keyword.get(config, :socket_path, "/var/run/docker.sock"),
      receive_timeout: :infinity
    )
  end

  defp as_nil(_), do: nil
end
