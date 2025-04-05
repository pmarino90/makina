defmodule Makina do
  @moduledoc """

  """

  @doc """
  Deploys a list of standalone application on a list of servers.

  Standalone applications do not have dependencies among each other and therefore
  they are deployed as they are listed.
  Errors in the process will be collected and reported but those will not affect the deployment of other applications also on the same server.

  Deployments happen sequentially server by server, application by application.
  """
  defdelegate deploy_standalone_applications(servers, applications), to: Makina.Applications
end
