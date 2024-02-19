defmodule MakinaWeb.AppLive do
  alias Makina.Runtime
  use MakinaWeb, :live_view

  import MakinaWeb.CoreComponents

  alias Makina.Apps

  def render(assigns) do
    ~H"""
    <.header>
      <%= @app.name %>
      <:actions>
        <button class="btn btn-primary" phx-click="start_app">Start</button>
        <button class="btn btn-primary" phx-click="stop_app" phx-disable-with="stopping...">
          Stop
        </button>
      </:actions>
    </.header>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    app = Apps.get_app!(String.to_integer(id))

    socket
    |> assign(app: app)
    |> wrap_ok()
  end

  def handle_event("stop_app", _data, socket) do
    Runtime.stop_app(socket.assigns.app.id)

    socket
    |> put_flash(:info, "Stop signal sent to app")
    |> wrap_noreply()
  end

  def handle_event("start_app", _data, socket) do
    Runtime.start_app(socket.assigns.app)

    socket
    |> put_flash(:info, "Start signal sent to app")
    |> wrap_noreply()
  end
end
