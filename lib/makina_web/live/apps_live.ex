defmodule MakinaWeb.AppsLive do
  use MakinaWeb, :live_view

  import MakinaWeb.CoreComponents

  alias Makina.Apps

  def render(assigns) do
    ~H"""
    <.header>
      Apps
      <:actions>
        <.link class="btn btn-primary" navigate={~p"/apps/create"}>Create</.link>
      </:actions>
    </.header>
    <section :if={@apps != []}>
      <section :for={app <- @apps}>
        <h4><%= app.name %></h4>
        <.link navigate={~p"/apps/#{app.id}"}>Go to app</.link>
      </section>
    </section>
    """
  end

  def mount(_params, _session, socket) do
    socket
    |> assign(:apps, Apps.list_applications())
    |> wrap_ok()
  end
end
