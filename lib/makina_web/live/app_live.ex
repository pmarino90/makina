defmodule MakinaWeb.AppLive do
  use MakinaWeb, :live_view

  import MakinaWeb.CoreComponents

  alias Phoenix.LiveView.AsyncResult
  alias Phoenix.PubSub

  alias Makina.{Apps, Runtime}

  def render(assigns) do
    ~H"""
    <div class="hstack justify-content-between gap-2 w-full">
      <div class="align-self-start mt-3">
        <.async_result :let={status} assign={@app_running_state}>
          <:loading>
            <div class="spinner-border small text-body-secondary" role="status">
              <span class="visually-hidden">Loading...</span>
            </div>
          </:loading>

          <span :if={status == :running} class="dot success"></span>
          <span :if={status != :running} class="dot danger"></span>
        </.async_result>
      </div>
      <.header class="flex-fill">
        <%= @app.name %>
        <:actions>
          <.dropdown placement="bottom-end">
            <:toggle_content>
              <.options_icon />
            </:toggle_content>
            <:elements>
              <.async_result :let={state} assign={@app_running_state}>
                <:loading>
                  <div class="spinner-border text-body-secondary" role="status">
                    <span class="visually-hidden">Loading...</span>
                  </div>
                </:loading>

                <button :if={state == :running} class="btn dropdown-item" phx-click="stop_app">
                  Stop
                </button>
                <button :if={state == :stopped} class="btn dropdown-item" phx-click="start_app">
                  Start
                </button>
              </.async_result>
            </:elements>
          </.dropdown>
        </:actions>
        <:subtitle><%= @app.description %></:subtitle>
      </.header>
    </div>

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
            <div class="hstack gap-2">
              <div class="mb-1">
                <.async_result :let={status} assign={@services_state["service-#{service.id}"]}>
                  <:loading>
                    <div class="spinner-border small text-body-secondary" role="status">
                      <span class="visually-hidden">Loading...</span>
                    </div>
                  </:loading>

                  <span :if={status == :running} class="dot success"></span>
                  <span :if={status != :running} class="dot danger"></span>
                </.async_result>
              </div>
              <h5 class="card-title"><%= service.name %></h5>
            </div>
            <div class="card-text"></div>
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

    if connected?(socket), do: PubSub.subscribe(Makina.PubSub, "app::#{app.id}")

    socket
    |> assign(app: app)
    |> assign(service_form: to_form(service_form))
    |> assign_async(:app_running_state, fn ->
      {:ok, %{app_running_state: Runtime.app_state(app.id)}}
    end)
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

  def handle_info({:service_update, :state, {state, service}}, socket) do
    services_state =
      socket.assigns.services_state
      |> Map.put("service-#{service.id}", AsyncResult.ok(state))

    socket
    |> assign(services_state: services_state)
    |> wrap_noreply()
  end

  def handle_info({:app_update, :state, {state}}, socket) do
    socket
    |> assign(app_running_state: AsyncResult.ok(state))
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
end
