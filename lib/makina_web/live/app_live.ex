defmodule MakinaWeb.AppLive do
  use MakinaWeb, :live_view

  import MakinaWeb.CoreComponents

  alias Phoenix.LiveView.AsyncResult
  alias Phoenix.PubSub

  alias Makina.{Apps, Runtime}

  def render(assigns) do
    ~H"""
    <section class="flex flex-col space-y-4">
      <header>
        <.header level="h2" class="text-2xl">
          <%= @app.name %>
          <:status_indicator>
            <.async_result :let={status} assign={@app_running_state}>
              <:loading>
                <.status_indicator status="loading" />
              </:loading>

              <.status_indicator :if={status == :running} status="running" />
              <.status_indicator :if={status != :running} status="stopped" />
            </.async_result>
          </:status_indicator>
          <:subtitle><%= @app.description %></:subtitle>
          <:actions>
            <.dropdown>
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
                  <.dropdown_element :if={state == :running}>
                    <button phx-click="stop_app" class="py-2 px-3 w-full text-left">
                      Stop
                    </button>
                  </.dropdown_element>
                  <.dropdown_element :if={state == :stopped}>
                    <button phx-click="start_app" class="py-2 px-3 w-full text-left">
                      Start
                    </button>
                  </.dropdown_element>
                </.async_result>
              </:elements>
            </.dropdown>
          </:actions>
        </.header>
      </header>

      <section>
        <.header level="h2" text_class="text-lg">
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

        <section :if={@app.services != []} class="grid grid-cols-4 gap-4 pt-5">
          <.card
            :for={service <- @app.services}
            title={service.name}
            cta_text="Go to service"
            cta_url={~p"/apps/#{@app.id}/services/#{service.id}"}
          >
            <:status_indicator>
              <.async_result :let={status} assign={@services_state["service-#{service.id}"]}>
                <:loading>
                  <.status_indicator status="loading" />
                </:loading>

                <.status_indicator :if={status == :running} status="running" />
                <.status_indicator :if={status != :running} status="stopped" />
              </.async_result>
            </:status_indicator>
          </.card>
        </section>
      </section>

      <.header level="h2" text_class="text-lg">
        API tokens
        <:subtitle>
          You can create and use API tokens to trigger service update and redeploy from other systems (GitHub, ...)
        </:subtitle>
        <:actions>
          <.button level="secondary" phx-click="create_api_token">
            <.icon name="hero-plus" />
          </.button>
        </:actions>
      </.header>

      <section>
        <section
          :if={@visible_token}
          class="text-sm flex flex-col bg-white border border-gray-200 shadow-sm rounded-xl p-4 md:p-5 dark:bg-slate-900 dark:border-gray-700 dark:text-gray-400"
        >
          <p>
            Your token has been created!
          </p>
          <p>
            You can use it to make requests at
            <span class="font-mono bg-slate-100 text-slate-700 text-sm p-1 border">/api/</span>
            by providing it as
            <span class="font-mono bg-slate-100 text-slate-700 text-sm p-1 border">
              Authorization
            </span>
            header.
          </p>

          <p>
            Example: <br />
            <span class="font-mono bg-slate-100 text-slate-700 text-sm p-1 border my-2 block">
              curl -H "Authorization: Bearer <%= @visible_token %>" https://instance.com/api/ping
            </span>
          </p>
          <p>
            You will be able to see and copy your token only once so save it somewhere safe (password manager or secret vault).
          </p>
          <input
            value={@visible_token}
            class="my-3 py-3 px-4 block w-full border rounded-lg text-sm placeholder:text-gray-400 focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-900 dark:border-gray-700 dark:text-gray-400 dark:placeholder:text-gray-500 dark:focus:ring-gray-600"
          />
        </section>

        <ul
          :if={@app.tokens != []}
          class="flex flex-col divide-y divide-gray-200 dark:divide-gray-700"
        >
          <li
            :for={token <- @app.tokens}
            class="inline-flex items-center gap-x-2 py-3 px-4 text-sm font-medium text-gray-800 dark:text-white"
          >
            <span>************</span> created at <span><%= token.inserted_at %></span>
          </li>
        </ul>
      </section>
    </section>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    app = Apps.get_app!(String.to_integer(id))

    if connected?(socket), do: PubSub.subscribe(Makina.PubSub, "app::#{app.id}")

    socket
    |> assign(app: app)
    |> assign(visible_token: nil)
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

  def handle_event("create_api_token", _data, socket) do
    token = Apps.create_api_token("api-token", socket.assigns.app)

    socket
    |> assign(visible_token: token)
    |> wrap_noreply()
  end

  def handle_async({:fetch_service_state, service_id}, {:ok, state}, socket) do
    services_state =
      socket.assigns.services_state
      |> Map.put("service-#{service_id}", AsyncResult.ok(state))

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
      start_async(sock, {:fetch_service_state, service.id}, fn ->
        Runtime.get_service_state(service.id, consolidated: true)
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
