defmodule MakinaWeb.ApiAuth do
  import Plug.Conn

  import Phoenix.Controller

  alias Makina.Stacks

  def verify_auth_token(conn, _opts) do
    %{"app_id" => app_id} = conn.path_params
    auth_token = get_token(conn)

    if auth_token != nil and Stacks.verify_token_for_app(app_id, auth_token) do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> put_view(MakinaWeb.ErrorJSON)
      |> render("401.json")
      |> halt()
    end
  end

  defp get_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ -> nil
    end
  end
end
