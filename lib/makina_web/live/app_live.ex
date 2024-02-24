defmodule MakinaWeb.AppLive do
  alias Phoenix.LiveView.AsyncResult
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
            <button :if={app_running?(@app.id)} class="btn dropdown-item" phx-click="stop_app">
              Stop
            </button>
            <button :if={!app_running?(@app.id)} class="btn dropdown-item" phx-click="start_app">
              Start
            </button>
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
              <.async_result :let={status} assign={@services_state["service-#{service.id}"]}>
                <:loading>
                  <div class="spinner-border text-body-secondary" role="status">
                    <span class="visually-hidden">Loading...</span>
                  </div>
                </:loading>

                <%= status %>
              </.async_result>
            </div>
            <.link navigate={~p"/apps/#{@app.id}/services/#{service.id}"}>
              Go to service
            </.link>
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
    |> fetch_and_assign_service_state()
    |> wrap_ok()
  end

  def handle_event("stop_app", _data, socket) do
    Runtime.stop_app(socket.assigns.app.id)

    socket
    |> wrap_noreply()
  end

  def handle_event("start_app", _data, socket) do
    Runtime.start_app(socket.assigns.app)

    socket
    |> wrap_noreply()
  end

  def handle_async(:fetch_service_state, {:ok, {service, state}}, socket) do
    services_state =
      socket.assigns.services_state
      |> Map.put("service-#{service.id}", AsyncResult.ok(state))

    socket
    |> assign(services_state: services_state)
    |> wrap_noreply()
  end

  defp fetch_and_assign_service_state(socket) do
    app = socket.assigns.app

    socket
    |> assign(services_state: loading_services_state(app.services))
    |> multi_fetch_state()
  end

  defp multi_fetch_state(socket) do
    services = socket.assigns.app.services

    services
    |> Enum.reduce(socket, fn service, sock ->
      start_async(sock, :fetch_service_state, fn ->
        {service, Runtime.get_service_state(service.id, consolidated: true)}
      end)
    end)
  end

  defp loading_services_state(services) do
    services
    |> Enum.reduce(%{}, fn service, acc ->
      Map.put(acc, "service-#{service.id}", AsyncResult.loading())
    end)
  end

  defp app_running?(id), do: Runtime.app_running?(id)
end
