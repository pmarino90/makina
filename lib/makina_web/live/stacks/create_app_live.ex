defmodule MakinaWeb.Stacks.CreateLive do
  use MakinaWeb, :live_view

  alias Makina.Stacks

  def render(assigns) do
    ~H"""
    <.header>
      Create Application
    </.header>
    <.simple_form
      :let={f}
      for={@form}
      phx-change="validate_application"
      phx-submit="create_application"
    >
      <.input field={f[:name]} label="Name" />
      <.input field={f[:description]} label="Description" />

      <:actions>
        <.button type="submit">Create</.button>
      </:actions>
    </.simple_form>
    """
  end

  def mount(_params, _session, socket) do
    form = Stacks.change_application() |> to_form(as: :application)

    socket
    |> assign(form: form)
    |> wrap_ok()
  end

  def handle_event("validate_application", data, socket) do
    form =
      Stacks.change_application(data)
      |> to_form(as: :application)

    socket
    |> assign(form: form)
    |> wrap_noreply()
  end

  def handle_event("create_application", data, socket) do
    current_user = socket.assigns.current_user

    case Stacks.create_application(Map.put(data, "owner_id", current_user.id)) do
      {:ok, app} ->
        socket
        |> push_navigate(to: ~p"/stacks/#{app.id}")
        |> put_flash(:info, "Your application has been created!")
        |> wrap_noreply()

      {:error, changeset} ->
        socket
        |> assign(form: to_form(changeset))
        |> put_flash(:error, "Could not create the app.")
        |> wrap_noreply()
    end
  end
end
