defmodule Makina.Runtime.App do
  @moduledoc """
  User can create apps, which are a collection of one or more services

  This module is responsible of Starting and supervising all the services
  that are part of a given app.
  """

  use Supervisor

  require Logger

  alias Makina.Runtime.Service

  def start_link({_, app} = args) do
    Supervisor.start_link(__MODULE__, args,
      name: {:via, Registry, {Makina.Runtime.Registry, "app-#{app.id}"}}
    )
  end

  def init({_, app_spec}) do
    if app_spec == nil, do: raise("Cannot start app with missing :app_spec")

    Logger.info("Starting app #{app_spec.name}, id: #{app_spec.id}")

    children =
      for service <- app_spec.services do
        build_child_spec(app_spec, service)
      end

    Supervisor.init(children, strategy: :one_for_one, max_seconds: 30)
  end

  def build_child_spec(app, service) do
    %{start: {Service, :start_link, [{app, service}]}, id: "service_#{service.id}"}
  end
end
