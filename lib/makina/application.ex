defmodule Makina.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MakinaWeb.Telemetry,
      Makina.Vault,
      Makina.Repo,
      {Ecto.Migrator, repos: Application.fetch_env!(:makina, :ecto_repos)},
      {DNSCluster, query: Application.get_env(:makina, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Makina.PubSub},
      {Finch, name: Makina.Finch},
      Makina.Runtime.Supervisor,
      MakinaWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Makina.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MakinaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
