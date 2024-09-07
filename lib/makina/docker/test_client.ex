defmodule Makina.Docker.TestClient do
  require Logger
  @behaviour Makina.Docker.Behaviour

  @impl true
  def create_container!(_name, %{} = _params) do
    not_implemented()
  end

  @impl true
  def start_container!(_name_or_id),
    do: not_implemented()

  @impl true
  def stop_container!(_name_or_id),
    do: not_implemented()

  @impl true
  def rename_container!(_name_or_id, _new_name),
    do: not_implemented()

  @impl true
  def remove_container!(_name_or_id),
    do: not_implemented()

  @impl true
  def wait_for_container!(_name_or_id),
    do: not_implemented()

  @impl true
  def logs_for_container!(_name_or_id, _into \\ nil),
    do: not_implemented()

  @impl true
  def create_image(params) when is_list(params) do
    not_implemented()
  end

  @impl true
  def inspect_image!(_name_or_id), do: not_implemented()

  @impl true
  def create_volume!(_name),
    do: not_implemented()

  @impl true
  def create_network!(_name),
    do: not_implemented()

  @impl true
  def inspect_network(_name), do: not_implemented()

  @impl true
  def connect_network!(_container, _network),
    do: not_implemented()

  # Service endpoints

  @impl true
  def ping(), do: {:ok, "Ok"}

  defp not_implemented(), do: Logger.error("Not implemented")
end
