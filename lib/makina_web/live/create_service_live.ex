defmodule MakinaWeb.CreateServiceLive do
  alias Makina.Apps
  use MakinaWeb, :live_view

  def render(assigns) do
    ~H"""
    <.header class="mb-5" text_class="text-xl">
      Create a new service
      <:subtitle>
        Add a new service to <span class="font-semibold"><%= @app.name %></span>
      </:subtitle>
    </.header>

    <section class="bg-white border shadow-sm rounded-xl dark:bg-slate-900 dark:border-gray-700 dark:shadow-slate-700/[.7]">
      <.form
        :let={f}
        for={@form}
        class="flex flex-col space-y-4 px-3 py-5"
        phx-change="validate_service"
        phx-submit="create_service"
      >
        <section class="flex flex-col space-y-4">
          <.header level="h3" text_class="text-lg">
            Container
            <:subtitle>
              Deployed container's info
            </:subtitle>
          </.header>
          <div class="flex flex-col space-y-2">
            <.input field={f[:name]} label="Name" autocomplete="false" />
            <.input field={f[:image_registry]} label="Image Registry" placeholder="hub.docker.com" />
            <.input field={f[:is_private_registry]} label="Private registry?" type="checkbox" />

            <.input
              :if={normalize_checbox(@form[:is_private_registry].value)}
              field={f[:image_registry_user]}
              label="Registry User"
            />
            <.input
              :if={normalize_checbox(@form[:is_private_registry].value)}
              field={f[:image_registry_unsafe_password]}
              label="Registry Password"
              type="password"
            />

            <.input field={f[:image_name]} label="Image Name" />
            <.input field={f[:image_tag]} label="Image Tag" />
            <.input field={f[:expose_service]} type="checkbox" label="Expose Service" />
          </div>
        </section>

        <section class="flex flex-col space-y-4">
          <.header level="h3" text_class="text-lg">
            Environment Variables
            <:subtitle>
              You can add environment variables for the service here. Note: all values are plaintext.
            </:subtitle>
          </.header>
          <.inputs_for :let={f_env} field={@form[:environment_variables]}>
            <input type="hidden" class="hidden" name="service[envs_sort][]" value={f_env.index} />
            <div class="flex space-x-2">
              <.input type="text" field={f_env[:name]} placeholder="name" />
              <.input type="text" field={f_env[:value]} placeholder="value" />
              <button
                name="service[envs_drop][]"
                type="button"
                class="py-3 px-4 inline-flex items-center gap-x-2 text-sm font-semibold rounded-lg border border-transparent text-gray-500 hover:bg-gray-100 disabled:opacity-50 disabled:pointer-events-none dark:text-gray-400 dark:hover:bg-gray-800 dark:focus:outline-none dark:focus:ring-1 dark:focus:ring-gray-600"
                value={f_env.index}
                phx-click={JS.dispatch("change")}
              >
                <.icon name="hero-minus" />
              </button>
            </div>
          </.inputs_for>

          <input type="hidden" name="service[envs_drop][]" />
          <button
            type="button"
            class="w-max py-3 px-4 inline-flex items-center gap-x-2 text-sm font-medium rounded-lg border border-gray-200 bg-white text-gray-800 shadow-sm hover:bg-gray-50 disabled:opacity-50 disabled:pointer-events-none dark:bg-slate-900 dark:border-gray-700 dark:text-white dark:hover:bg-gray-800 dark:focus:outline-none dark:focus:ring-1 dark:focus:ring-gray-600"
            name="service[envs_sort][]"
            value="new"
            phx-click={JS.dispatch("change")}
          >
            <.icon name="hero-plus" />
          </button>
        </section>

        <section class="flex flex-col space-y-4">
          <.header level="h3">
            Volumes
            <:subtitle>
              You can define volumes that are going to be attached to the service once running.
            </:subtitle>
          </.header>
          <.inputs_for :let={f_env} field={@form[:volumes]}>
            <input type="hidden" class="hidden" name="service[volumes_sort][]" value={f_env.index} />
            <div class="flex space-x-2">
              <.input type="text" field={f_env[:name]} placeholder="name" />
              <.input type="text" field={f_env[:mount_point]} placeholder="mount point" />
              <button
                name="service[volumes_drop][]"
                type="button"
                class="py-3 px-4 inline-flex items-center gap-x-2 text-sm font-semibold rounded-lg border border-transparent text-gray-500 hover:bg-gray-100 disabled:opacity-50 disabled:pointer-events-none dark:text-gray-400 dark:hover:bg-gray-800 dark:focus:outline-none dark:focus:ring-1 dark:focus:ring-gray-600"
                value={f_env.index}
                phx-click={JS.dispatch("change")}
              >
                <.icon name="hero-minus" />
              </button>
            </div>
          </.inputs_for>

          <input type="hidden" name="service[volumes_drop][]" />

          <button
            type="button"
            class="w-max py-3 px-4 inline-flex items-center gap-x-2 text-sm font-medium rounded-lg border border-gray-200 bg-white text-gray-800 shadow-sm hover:bg-gray-50 disabled:opacity-50 disabled:pointer-events-none dark:bg-slate-900 dark:border-gray-700 dark:text-white dark:hover:bg-gray-800 dark:focus:outline-none dark:focus:ring-1 dark:focus:ring-gray-600"
            name="service[volumes_sort][]"
            value="new"
            phx-click={JS.dispatch("change")}
          >
            <.icon name="hero-plus" />
          </button>
        </section>

        <section
          :if={normalize_checbox(@form[:expose_service].value) == true}
          class="flex flex-col space-y-4"
        >
          <.header level="h3">
            Domains
            <:subtitle>
              Specify here the domains you want the given service to be exposed
            </:subtitle>
          </.header>
          <.inputs_for :let={f_env} field={@form[:domains]}>
            <input type="hidden" class="hidden" name="service[domains_sort][]" value={f_env.index} />
            <div class="flex space-x-2">
              <.input type="text" field={f_env[:domain]} placeholder="domain" />
              <button
                name="service[domains_drop][]"
                type="button"
                class="py-3 px-4 inline-flex items-center gap-x-2 text-sm font-semibold rounded-lg border border-transparent text-gray-500 hover:bg-gray-100 disabled:opacity-50 disabled:pointer-events-none dark:text-gray-400 dark:hover:bg-gray-800 dark:focus:outline-none dark:focus:ring-1 dark:focus:ring-gray-600"
                value={f_env.index}
                phx-click={JS.dispatch("change")}
              >
                <.icon name="hero-minus" />
              </button>
            </div>
          </.inputs_for>

          <input type="hidden" name="service[domains_drop][]" />
          <button
            type="button"
            class="w-max py-3 px-4 inline-flex items-center gap-x-2 text-sm font-medium rounded-lg border border-gray-200 bg-white text-gray-800 shadow-sm hover:bg-gray-50 disabled:opacity-50 disabled:pointer-events-none dark:bg-slate-900 dark:border-gray-700 dark:text-white dark:hover:bg-gray-800 dark:focus:outline-none dark:focus:ring-1 dark:focus:ring-gray-600"
            name="service[domains_sort][]"
            value="new"
            phx-click={JS.dispatch("change")}
          >
            <.icon name="hero-plus" />
          </button>
        </section>

        <div class="flex justify-between">
          <.link
            navigate={~p"/apps/#{@app.id}"}
            class="inline-flex items-center gap-x-2 text-sm font-semibold rounded-lg text-gray-800 hover:text-blue-600 disabled:opacity-50 disabled:pointer-events-none dark:text-white dark:hover:text-white/70 dark:focus:outline-none dark:focus:ring-1 dark:focus:ring-gray-600"
          >
            <.icon name="hero-arrow-left" /><span>Go Back</span>
          </.link>
          <button class="py-3 px-4 inline-flex items-center gap-x-2 text-sm font-semibold rounded-lg border border-transparent bg-gray-800 text-white hover:bg-gray-900 disabled:opacity-50 disabled:pointer-events-none dark:focus:outline-none dark:focus:ring-1 dark:focus:ring-gray-600 dark:bg-white dark:text-gray-800">
            Save
          </button>
        </div>
      </.form>
    </section>
    """
  end

  def mount(%{"app_id" => app_id}, _session, socket) do
    app = Apps.get_app!(String.to_integer(app_id))
    form = Apps.change_service()

    socket
    |> assign(app: app)
    |> assign(form: to_form(form))
    |> wrap_ok()
  end

  def handle_event("validate_service", %{"service" => service}, socket) do
    changeset = Apps.change_service(service)

    socket
    |> assign(form: to_form(changeset))
    |> wrap_noreply()
  end

  def handle_event("create_service", %{"service" => service}, socket) do
    app = socket.assigns.app

    case Apps.create_service(Map.put(service, "application_id", app.id)) do
      {:ok, _service} ->
        socket
        |> put_flash(:info, "Service created")
        |> push_navigate(to: ~p"/apps/#{app.id}")
        |> wrap_noreply()

      {:error, changeset} ->
        dbg(changeset)

        socket
        |> put_flash(:error, "Could not create the service")
        |> assign(form: to_form(changeset))
        |> wrap_noreply()
    end
  end

  defp normalize_checbox(value), do: Phoenix.HTML.Form.normalize_value("checkbox", value)
end
