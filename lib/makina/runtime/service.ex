defmodule Makina.Runtime.Service do
  @moduledoc """
  An app can be build by one or more services.

  This module is responsible of starting all the instances of the given service
  and supervise them in order to ensure they are properly running.
  """

  use Supervisor

  require Logger

  # alias Makina.Runtime.Instance
  alias Makina.Runtime.Instance.Docker

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init({app, service}) do
    children = [
      %{
        id: "service_#{service.id}",
        start: {Docker, :start_link, [{self(), app, service, []}]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one, max_seconds: 30)
  end
end
