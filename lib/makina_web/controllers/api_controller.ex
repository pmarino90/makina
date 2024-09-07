defmodule MakinaWeb.ApiController do
  use MakinaWeb, :controller

  alias Makina.Stacks

  def service_redeploy(conn, %{"service_id" => service_id}) do
    service = Stacks.get_service!(String.to_integer(service_id))

    Stacks.trigger_service_redeploy(service)

    conn
    |> render(:service_redeploy)
  end
end
