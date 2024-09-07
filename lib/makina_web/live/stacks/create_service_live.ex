defmodule MakinaWeb.Stacks.CreateServiceLive do
  alias MakinaWeb.ServiceComponents
  alias Makina.Stacks
  use MakinaWeb, :live_view

  def render(assigns) do
    ~H"""
    <.header class="mb-5" text_class="text-xl">
      Create a new service
      <:subtitle>
        Add a new service to <span class="font-semibold"><%= @stack.name %></span>
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
              field={f[:image_registry_password]}
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

          <ServiceComponents.environment_form form={@form[:environment_variables]} />
        </section>

        <section class="flex flex-col space-y-4">
          <.header level="h3">
            Volumes
            <:subtitle>
              You can define volumes that are going to be attached to the service once running.
            </:subtitle>
          </.header>
          <ServiceComponents.volumes_form form={@form[:volumes]} />
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

          <ServiceComponents.domains_form form={@form[:domains]} />
        </section>

        <div class="flex justify-between">
          <.link
            navigate={~p"/stacks/#{@stack.id}"}
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

  def mount(%{"stack_id" => stack_id}, _session, socket) do
    stack = Stacks.get_app!(String.to_integer(stack_id))
    form = Stacks.change_service()

    socket
    |> assign(stack: stack)
    |> assign(form: to_form(form))
    |> wrap_ok()
  end

  def handle_event("validate_service", %{"service" => service}, socket) do
    changeset = Stacks.change_service(service)

    socket
    |> assign(form: to_form(changeset))
    |> wrap_noreply()
  end

  def handle_event("create_service", %{"service" => service}, socket) do
    stack = socket.assigns.stack

    case Stacks.create_service(Map.put(service, "application_id", stack.id)) do
      {:ok, service} ->
        socket
        |> put_flash(:info, "Service created")
        |> push_navigate(to: ~p"/stacks/#{stack.id}/services/#{service.id}/logs")
        |> wrap_noreply()

      {:error, changeset} ->
        socket
        |> put_flash(:error, "Could not create the service")
        |> assign(form: to_form(changeset))
        |> wrap_noreply()
    end
  end

  defp normalize_checbox(value), do: Phoenix.HTML.Form.normalize_value("checkbox", value)
end
