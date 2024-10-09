defmodule Makina.Runtime.SupportServices do
  use Supervisor

  require Logger

  alias Makina.Stacks.Volume
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
    docker_config = Application.get_env(:makina, Makina.Docker, [])
    runtime_config = Application.get_env(:makina, Makina.Runtime)
    proxy_config = runtime_config[:proxy]

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
              expose_service: true,
              volumes: [
                %Volume{
                  name: "docker-socket",
                  mount_point: "/var/run/docker.sock",
                  local_path: docker_config[:socket_path]
                },
                %Volume{
                  name: "acme-file",
                  mount_point: "/acme.json",
                  local_path: proxy_config[:letsencrypt_acme_path]
                }
              ],
              domains: [],
              command: reverse_proxy_base_config() ++ reverse_proxy_https_config()
            }, []}
         ]}
    }
  end

  defp reverse_proxy_base_config() do
    [
      "--entryPoints.web.address=:80",
      "--api.insecure=true",
      "--providers.docker",
      "--providers.docker.exposedByDefault=false",
      "--providers.docker.network=makina_web-net"
    ]
  end

  defp reverse_proxy_https_config() do
    config = Application.get_env(:makina, Makina.Runtime)

    if Keyword.get(config, :enable_https, true) do
      [
        "--entryPoints.websecure.address=:443",
        "--entryPoints.web.http.redirections.entryPoint.to=websecure",
        "--entryPoints.web.http.redirections.entryPoint.permanent=true",
        "--entryPoints.web.http.redirections.entryPoint.scheme=https",
        "--certificatesResolvers.letsencrypt.acme.email=<email>",
        " --certificatesResolvers.letsencrypt.acme.storage=acme.json",
        " --certificatesResolvers.letsencrypt.acme.keyType=EC384",
        " --certificatesResolvers.letsencrypt.acme.httpChallenge.entryPoint=web"
      ]
    else
      []
    end
  end
end
