defmodule Makina.Runtime.SupportServices do
  use Supervisor

  require Logger

  alias Makina.Runtime.Instance.Docker
  alias Makina.Stacks.Service
  alias Makina.Stacks.Stack

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_args) do
    Logger.info("Starting support services")

    children = [reverse_proxy()]

    Supervisor.init(children, strategy: :one_for_one, max_seconds: 30)
  end

  defp reverse_proxy() do
    %{
      id: "makina-support-reverse_proxy",
      start:
        {Docker, :start_link,
         [
           {self(), %Stack{id: 00, slug: "makina-support"},
            %Service{
              id: 00,
              slug: "reverse-proxy",
              image_tag: "v2.11",
              image_name: "traefik",
              environment_variables: [],
              volumes: [],
              domains: []
            }, []}
         ]}
    }
  end
end
