defmodule MakinaWeb.ApiController do
  use MakinaWeb, :controller

  alias Makina.Apps

  def service_redeploy(conn, %{"service_id" => service_id}) do
    service = Apps.get_service!(String.to_integer(service_id))

    Apps.trigger_service_redeploy(service)

    conn
    |> render(:service_redeploy)
  end
end
