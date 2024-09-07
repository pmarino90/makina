defmodule MakinaWeb.Stacks.ViewServiceLive do
  use MakinaWeb, :live_view

  import MakinaWeb.CoreComponents

  alias Phoenix.PubSub
  alias Phoenix.LiveView.AsyncResult
  alias Makina.Runtime
  alias Makina.Stacks
  alias Makina.Stacks.Service
  alias MakinaWeb.ServiceComponents

  def render(assigns) do
    ~H"""
    <div class="flex flex-col space-y-5">
      <.breadcrumb>
        <:crumb navigate={~p"/"}>
          Stacks
        </:crumb>
        <:crumb navigate={~p"/stacks/#{@stack.id}"}>
          <%= @stack.name %>
        </:crumb>
        <:crumb current>
          <%= @service.name %>
        </:crumb>
      </.breadcrumb>

      <section class="flex flex-col bg-white border shadow-sm rounded-xl dark:bg-slate-900 dark:border-gray-700 dark:shadow-slate-700/[.7]">
        <div class="p-4 md:p-10">
          <.header level="h3" text_class="text-lg font-bold text-gray-800 dark:text-white">
            <%= @service.name %>
            <:status_indicator>
              <.async_result :let={status} assign={@service_running_state}>
                <:loading>
                  <.status_indicator status="loading" />
                </:loading>

                <.status_indicator :if={status == :running} status="running" />
                <.status_indicator :if={status != :running} status="stopped" />
              </.async_result>
            </:status_indicator>
          </.header>
        </div>
      </section>

      <div class="flex">
        <div class="flex bg-gray-100 hover:bg-gray-200 rounded-lg transition p-1 dark:bg-gray-700 dark:hover:bg-gray-600">
          <nav class="flex space-x-2" aria-label="Tabs">
            <.link
              class={[
                @current_tab == :settings &&
                  "bg-white text-gray-700 dark:text-gray-400 dark:bg-gray-800",
                "py-3 px-4 inline-flex items-center gap-x-2 bg-transparent text-sm text-gray-500 hover:text-gray-700 font-medium rounded-lg hover:hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none dark:text-gray-400 dark:hover:text-white active"
              ]}
              id="tab-settings"
              data-controller="hotkey"
              data-hotkey="s"
              aria-controls="settings"
              role="tab"
              patch={~p"/stacks/#{@stack.id}/services/#{@service.id}/"}
            >
              Settings <kbd class="text-xs font-mono bg-slate-100 px-1">s</kbd>
            </.link>
            <.link
              type="button"
              class={[
                @current_tab == :logs &&
                  "bg-white text-gray-700 dark:text-gray-400 dark:bg-gray-800",
                "py-3 px-4 inline-flex items-center gap-x-2 bg-transparent text-sm text-gray-500 hover:text-gray-700 font-medium rounded-lg hover:hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none dark:text-gray-400 dark:hover:text-white"
              ]}
              data-controller="hotkey"
              data-hotkey="l"
              id="tab-logs"
              aria-controls="logs"
              role="tab"
              patch={~p"/stacks/#{@stack.id}/services/#{@service.id}/logs"}
            >
              Logs <kbd class="text-xs font-mono bg-slate-100 px-1">l</kbd>
            </.link>
          </nav>
        </div>
      </div>

      <div class="mt-3">
        <div :if={@current_tab == :settings} role="tabpanel" aria-labelledby="tab-settings">
          <section class="flex flex-col space-y-4">
            <section class="text-sm">
              <.header level="h4" text_class="text-lg">
                Container
                <:subtitle>
                  Deployed container's info
                </:subtitle>
              </.header>

              <ul class="flex flex-col divide-y divide-gray-200 dark:divide-gray-700">
                <li class="inline-flex items-center gap-x-2 py-3 px-4 text-sm font-medium text-gray-800 dark:text-white">
                  <span class="font-semibold">Registry </span><%= @service.image_registry %>
                </li>
                <li class="inline-flex items-center gap-x-2 py-3 px-4 text-sm font-medium text-gray-800 dark:text-white">
                  <span class="font-semibold">Image and tag </span><%= "#{@service.image_name}:#{@service.image_tag}" %>
                </li>
                <li
                  :if={@service.image_registry_user}
                  class="inline-flex items-center gap-x-2 py-3 px-4 text-sm font-medium text-gray-800 dark:text-white"
                >
                  <span class="font-semibold">Registry User </span><%= @service.image_registry_user %>
                </li>
              </ul>
            </section>

            <section class={[
              not is_nil(@edit_mode) and @edit_mode != :domains && "opacity-50"
            ]}>
              <.header level="h4" text_class="text-lg">
                Domains
                <:subtitle>
                  Domains to which the service can be reached at if exposed to the web (HTTPS only)
                </:subtitle>
                <:actions>
                  <ServiceComponents.section_edit_actions edit_mode={@edit_mode} section={:domains} />
                </:actions>
              </.header>

              <.form
                :if={@edit_mode == :domains}
                id="domains-update-form"
                for={@form}
                phx-change="validate_domains"
                phx-submit="update_domains"
              >
                <ServiceComponents.domains_form form={@form[:domains]} />
              </.form>

              <ul
                :if={@service.expose_service and @edit_mode != :domains}
                class="flex flex-col divide-y divide-gray-200 dark:divide-gray-700 font-mono"
              >
                <li
                  :for={domain <- @service.domains}
                  class="inline-flex items-center gap-x-2 py-3 px-4 text-sm font-medium text-gray-800 dark:text-white"
                >
                  <%= domain.domain %>
                </li>
              </ul>
              <p :if={@service.expose_service == false}>
                This service is not exposed to the web. Enable it.
              </p>
            </section>

            <section class={[
              not is_nil(@edit_mode) and @edit_mode != :environment_variables && "opacity-50"
            ]}>
              <.header level="h4" text_class="text-lg">
                Environment variables
                <:subtitle>
                  Environment variables exposed to the service (plain text only).
                </:subtitle>
                <:actions>
                  <ServiceComponents.section_edit_actions
                    edit_mode={@edit_mode}
                    section={:environment_variables}
                  />
                </:actions>
              </.header>

              <.form
                :if={@edit_mode == :environment_variables}
                id="environment_variables-update-form"
                for={@form}
                phx-change="validate_environment_variables"
                phx-submit="update_environment_variables"
              >
                <ServiceComponents.environment_form form={@form[:environment_variables]} />
              </.form>

              <div :if={@edit_mode != :environment_variables}>
                <ul
                  :if={@service.environment_variables != []}
                  class="flex flex-col divide-y divide-gray-200 dark:divide-gray-700 font-mono"
                >
                  <li
                    :for={var <- @service.environment_variables}
                    class="inline-flex items-center gap-x-2 py-3 px-4 text-sm font-medium text-gray-800 dark:text-white"
                  >
                    <%= "#{var.name} = #{ServiceComponents.display_env_var_value(var)}" %>
                  </li>
                </ul>
              </div>
            </section>

            <section class={[
              not is_nil(@edit_mode) and @edit_mode != :volumes && "opacity-50"
            ]}>
              <.header level="h4" text_class="text-lg">
                Volumes
                <:subtitle>
                  Volumes mounted to the container to provide persistant storage
                </:subtitle>
                <:actions>
                  <ServiceComponents.section_edit_actions edit_mode={@edit_mode} section={:volumes} />
                </:actions>
              </.header>

              <.form
                :if={@edit_mode == :volumes}
                id="volumes-update-form"
                for={@form}
                phx-change="validate_volumes"
                phx-submit="update_volumes"
              >
                <ServiceComponents.volumes_form form={@form[:volumes]} />
              </.form>

              <div :if={@edit_mode != :volumes}>
                <ul
                  :if={@service.volumes != []}
                  class="flex flex-col divide-y divide-gray-200 dark:divide-gray-700 font-mono"
                >
                  <li
                    :for={vol <- @service.volumes}
                    class="inline-flex items-center gap-x-2 py-3 px-4 text-sm font-medium text-gray-800 dark:text-white"
                  >
                    <%= "#{vol.name} = #{vol.mount_point}" %>
                  </li>
                </ul>
              </div>
            </section>
            <section class={[
              not is_nil(@edit_mode) && "opacity-50"
            ]}>
              <.header level="h4" text_class="text-lg">
                Service Lifecycle
                <:subtitle>
                  Turn off, restart or delete your service
                </:subtitle>
              </.header>
              <ol class="flex mt-2 space-x-3">
                <li>
                  <.async_result :let={status} assign={@service_running_state}>
                    <:loading>
                      <.status_indicator status="loading" />
                    </:loading>
                    <.button :if={status == :running} level="secondary" phx-click="stop_service">
                      Stop
                    </.button>
                    <.button :if={status != :running} level="secondary" phx-click="start_service">
                      Start
                    </.button>
                  </.async_result>
                </li>
                <li>
                  <.button
                    level="secondary"
                    phx-click="delete_service"
                    data-confirm="Are you sure you want to delete the current service?"
                  >
                    Delete
                  </.button>
                </li>
              </ol>
            </section>
          </section>
        </div>
        <div :if={@current_tab == :logs} role="tabpanel" aria-labelledby="tab-logs">
          <div id="logs" phx-update="ignore" class="p-2 bg-black" data-controller="xterm"></div>
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"stack_id" => stack_id, "service_id" => service_id}, _session, socket) do
    stack = Stacks.get_app!(String.to_integer(stack_id))
    service = Stacks.get_service!(String.to_integer(service_id))

    if connected?(socket), do: PubSub.subscribe(Makina.PubSub, "stack::#{stack.id}")

    socket
    |> assign(stack: stack)
    |> assign(edit_mode: nil)
    |> assign(form: nil)
    |> assign(service: service)
    |> assign(current_tab: :settings)
    |> assign_async(
      :service_running_state,
      fn ->
        {:ok, %{service_running_state: Runtime.get_service_state(service.id, consolidated: true)}}
      end
    )
    |> wrap_ok()
  end

  def handle_params(_params, uri, socket) do
    service = socket.assigns.service

    if String.ends_with?(uri, "/logs") do
      PubSub.subscribe(Makina.PubSub, "system::service::#{service.id}::logs")

      socket
      |> assign(current_tab: :logs)
      |> stream(:logs, [])
      |> wrap_noreply()
    else
      PubSub.unsubscribe(Makina.PubSub, "system::service::#{service.id}::logs")

      socket
      |> assign(current_tab: :settings)
      |> wrap_noreply()
    end
  end

  def handle_event("validate_domains", %{"service" => data}, socket) do
    changeset = Stacks.change_service_domains(%Service{}, data)

    socket
    |> assign(form: to_form(changeset))
    |> wrap_noreply()
  end

  def handle_event("update_domains", %{"service" => data}, socket) do
    service = socket.assigns.service

    case Stacks.update_service_domains(service, data) do
      {:ok, service} ->
        socket
        |> assign(service: service)
        |> assign(form: nil)
        |> assign(edit_mode: nil)
        |> wrap_noreply()

      {:error, changeset} ->
        socket
        |> assign(form: to_form(changeset))
        |> wrap_noreply()
    end
  end

  def handle_event("validate_environment_variables", %{"service" => data}, socket) do
    changeset = Stacks.change_service_environment_variables(%Service{}, data)

    socket
    |> assign(form: to_form(changeset))
    |> wrap_noreply()
  end

  def handle_event("update_environment_variables", %{"service" => data}, socket) do
    service = socket.assigns.service

    case Stacks.update_service_environment_variables(service, data) do
      {:ok, service} ->
        socket
        |> assign(service: service)
        |> assign(form: nil)
        |> assign(edit_mode: nil)
        |> wrap_noreply()

      {:error, changeset} ->
        socket
        |> assign(form: to_form(changeset))
        |> wrap_noreply()
    end
  end

  def handle_event("validate_volumes", %{"service" => data}, socket) do
    changeset = Stacks.change_service_volumes(%Service{}, data)

    socket
    |> assign(form: to_form(changeset))
    |> wrap_noreply()
  end

  def handle_event("update_volumes", %{"service" => data}, socket) do
    service = socket.assigns.service

    case Stacks.update_service_volumes(service, data) do
      {:ok, service} ->
        socket
        |> assign(service: service)
        |> assign(form: nil)
        |> assign(edit_mode: nil)
        |> wrap_noreply()

      {:error, changeset} ->
        socket
        |> assign(form: to_form(changeset))
        |> wrap_noreply()
    end
  end

  def handle_event("set_edit_mode", %{"value" => "domains"}, socket) do
    changeset = Stacks.change_service_domains(socket.assigns.service)

    socket
    |> assign(edit_mode: :domains)
    |> assign(form: to_form(changeset))
    |> wrap_noreply()
  end

  def handle_event("set_edit_mode", %{"value" => "environment_variables"}, socket) do
    changeset = Stacks.change_service_environment_variables(socket.assigns.service)

    socket
    |> assign(edit_mode: :environment_variables)
    |> assign(form: to_form(changeset))
    |> wrap_noreply()
  end

  def handle_event("set_edit_mode", %{"value" => "volumes"}, socket) do
    changeset = Stacks.change_service_volumes(socket.assigns.service)

    socket
    |> assign(edit_mode: :volumes)
    |> assign(form: to_form(changeset))
    |> wrap_noreply()
  end

  def handle_event("cancel_edit", _data, socket) do
    socket
    |> assign(form: nil)
    |> assign(edit_mode: nil)
    |> wrap_noreply()
  end

  def handle_event("stop_service", _data, socket) do
    Runtime.stop_service(socket.assigns.service)

    socket
    |> wrap_noreply()
  end

  def handle_event("start_service", _data, socket) do
    Runtime.start_service(socket.assigns.stack, socket.assigns.service)

    socket
    |> wrap_noreply()
  end

  def handle_event("delete_service", _data, socket) do
    Stacks.delete_service(socket.assigns.service)

    socket
    |> push_navigate(to: ~p"/stacks/#{socket.assigns.stack.id}")
    |> wrap_noreply()
  end

  def handle_info({:service_update, :state, {state, service}}, socket) do
    if service.id == socket.assigns.service.id do
      socket
      |> assign(service_running_state: AsyncResult.ok(state))
      |> wrap_noreply()
    else
      socket
      |> wrap_noreply()
    end
  end

  def handle_info({:stack_update, :state, {_state}}, socket) do
    socket
    |> wrap_noreply()
  end

  def handle_info({:log_entry, entry}, socket) do
    socket
    |> push_event("log_update", %{entry: entry})
    |> wrap_noreply()
  end
end
