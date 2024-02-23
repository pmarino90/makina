defmodule MakinaWeb.CreateServiceLive do
  alias Makina.Apps
  use MakinaWeb, :live_view

  def render(assigns) do
    ~H"""
    <.header>
      <%= "#{@app.name} > Create Service" %>
    </.header>

    <section>
      <.form
        :let={f}
        for={@form}
        class="vstack gap-3"
        phx-change="validate_service"
        phx-submit="create_service"
      >
        <section>
          <.header level="h3">General Information</.header>
          <div class="vstack gap-2">
            <.input field={f[:name]} label="Name" autocomplete="false" />
            <.input field={f[:image_registry]} label="Image Registry" value="hub.docker.com" />
            <.input field={f[:image_name]} label="Image Name" />
            <.input field={f[:image_tag]} label="Image Tag" />
          </div>
        </section>
        <section>
          <.header level="h3">
            Environment Variables
            <:subtitle>
              You can add environment variables for the service here. Note: all values are plaintext.
            </:subtitle>
          </.header>
          <.inputs_for :let={f_env} field={@form[:environment_variables]}>
            <input type="hidden" class="hidden" name="service[envs_sort][]" value={f_env.index} />
            <div class="hstack gap-2">
              <.input type="text" field={f_env[:name]} placeholder="name" />
              <.input type="text" field={f_env[:value]} placeholder="value" />
              <button
                name="service[envs_drop][]"
                type="button"
                class="btn"
                value={f_env.index}
                phx-click={JS.dispatch("change")}
              >
                <.minus_icon />
              </button>
            </div>
          </.inputs_for>

          <input type="hidden" name="service[envs_drop][]" />
          <button
            type="button"
            class="btn btn-secondary"
            name="service[envs_sort][]"
            value="new"
            phx-click={JS.dispatch("change")}
          >
            Add
          </button>
        </section>
        <div class="hstack justify-content-end">
          <button class="btn btn-primary">Save</button>
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
        socket
        |> put_flash(:error, "Could not create the service")
        |> assign(form: to_form(changeset))
        |> wrap_noreply()
    end
  end
end
