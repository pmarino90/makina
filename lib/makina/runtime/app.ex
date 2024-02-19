defmodule Makina.Runtime.App do
  @moduledoc """
  User can create apps, which are a collection of one or more services

  This module is responsible of Starting and supervising all the services
  that are part of a given app.
  """

  use Supervisor

  require Logger

  alias Makina.Runtime.Service

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init({_, app_spec}) do
    if app_spec == nil, do: raise("Cannot start app with missing :app_spec")

    Logger.info("Starting app #{app_spec.name}, id: #{app_spec.id}")

    children =
      for service <- app_spec.services do
        %{start: {Service, :start_link, [service: service]}, id: "service_#{service.id}"}
      end

    Supervisor.init(children, strategy: :one_for_one, max_seconds: 30)
  end
end
