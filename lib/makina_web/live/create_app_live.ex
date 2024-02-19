defmodule MakinaWeb.CreateAppLive do
  use MakinaWeb, :live_view

  alias Makina.{Runtime, Apps}

  def render(assigns) do
    ~H"""
    <.header>
      Create Application
      <:subtitle>
        Create a new application with docker container information.
      </:subtitle>
    </.header>
    <.simple_form :let={f} for={%{}} phx-submit="create_application">
      <.input field={f[:name]} label="Name" />
      <.input field={f[:description]} label="Description" />
      <.input field={f[:image_name]} label="Image Name" />
      <.input field={f[:image_tag]} label="Image Tag" />

      <:actions>
        <.button type="submit">Create</.button>
      </:actions>
    </.simple_form>
    """
  end

  def handle_event("create_application", data, socket) do
    app_data = %{
      "name" => data["name"],
      "description" => data["description"],
      "owner_id" => socket.assigns.current_user.id,
      "services" => [
        %{
          "name" => data["name"],
          "image_name" => data["image_name"],
          "image_tag" => data["image_tag"]
        }
      ]
    }

    case Apps.create_application(app_data) do
      {:ok, app} ->
        Runtime.start_app(app)

        socket
        |> push_navigate(to: ~p"/apps/#{app.id}")
        |> put_flash(:info, "Your application has been created!")
        |> wrap_noreply()

      {:error, changeset} ->
        dbg(changeset)

        socket
        |> put_flash(:error, "Could not create the app.")
        |> wrap_noreply()
    end
  end
end
