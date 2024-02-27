defmodule MakinaWeb.ServiceLive do
  use MakinaWeb, :live_view

  import MakinaWeb.CoreComponents

  alias Makina.Apps

  def render(assigns) do
    ~H"""
    <.header>
      <%= "#{@app.name} > #{@service.name}" %>
    </.header>
    """
  end

  def mount(%{"app_id" => app_id, "service_id" => service_id}, _session, socket) do
    app = Apps.get_app!(String.to_integer(app_id))
    service = Apps.get_service!(String.to_integer(service_id))

    socket
    |> assign(app: app)
    |> assign(service: service)
    |> wrap_ok()
  end
end
