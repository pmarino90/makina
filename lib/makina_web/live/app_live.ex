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
        <.dropdown placement="bottom-end">
          <:toggle_content>
            <.options_icon />
          </:toggle_content>
          <:elements>
            <.dropdown_element>
              <button class="btn">Foo</button>
            </.dropdown_element>
          </:elements>
        </.dropdown>
      </:actions>
      <:subtitle><%= @app.description %></:subtitle>
    </.header>

    <section>
      <.header level="h2">
        Services
        <:subtitle>
          Add services that compose your application (webapp, database, background job, ...)
        </:subtitle>
        <:actions>
          <.link class="btn" navigate={~p"/apps/#{@app.id}/services/create"}>
            <.list_plus_icon />
          </.link>
        </:actions>
      </.header>

      <section :if={@app.services == []}>
        No services, create one
      </section>

      <section :if={@app.services != []} class="d-flex flex-row">
        <article :for={service <- @app.services} class="card p-2">
          <div class="card-body">
            <h5 class="card-title"><%= service.name %></h5>
            <div class="card-text">
              <.link navigate={~p"/apps/#{@app.id}/services/#{service.id}"}>
                Go to service
              </.link>
            </div>
          </div>
        </article>
      </section>
    </section>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    app = Apps.get_app!(String.to_integer(id))
    service_form = Apps.change_service()

    socket
    |> assign(app: app)
    |> assign(service_form: to_form(service_form))
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
