defmodule Makina.Infrastructure.DockerTest do
  use ExUnit.Case, async: true

  alias Makina.Models.Server
  alias Makina.Models.Application

  alias Makina.Infrastructure.RemoteCommand

  alias Makina.Infrastructure.Docker

  describe "inspect/2" do
    test "returns a complete command to inspect a container" do
      server =
        Server.new(host: "example.com")
        |> Server.put_private(:conn_ref, self())

      app =
        Application.new(name: "foo")
        |> Application.set_docker_image(name: "nginx", tag: "1.16")

      cmd = Docker.inspect(server, app)

      assert is_struct(cmd, RemoteCommand)

      assert cmd.cmd == "docker inspect --type=container foo"
      assert cmd.server == server
    end

    test "returns a command to inspect a container by its name" do
      server =
        Server.new(host: "example.com")
        |> Server.put_private(:conn_ref, self())

      cmd = Docker.inspect(server, "foo")

      assert is_struct(cmd, RemoteCommand)

      assert cmd.cmd == "docker inspect --type=container foo"
    end
  end

  describe "run/2" do
    test "returns a command to run a container on a server" do
      server =
        Server.new(host: "example.com")
        |> Server.put_private(:conn_ref, self())

      app =
        Application.new(name: "foo")
        |> Application.set_docker_image(name: "nginx", tag: "1.16")

      cmd = Docker.run(server, app)

      assert is_struct(cmd, RemoteCommand)
      assert cmd.server == server

      assert cmd.cmd ==
               "docker run -d --restart unless-stopped --name foo --label org.makina.app.hash=#{app.__hash__} nginx:1.16"
    end

    test "contains volumes" do
      server =
        Server.new(host: "example.com")
        |> Server.put_private(:conn_ref, self())

      app =
        Application.new(name: "foo")
        |> Application.set_docker_image(name: "nginx", tag: "1.16")
        |> Application.put_volume(source: "foo", destination: "/app/data")

      cmd = Docker.run(server, app)

      assert cmd.cmd ==
               "docker run -d --restart unless-stopped --name foo --label org.makina.app.hash=#{app.__hash__} --volume foo:/app/data nginx:1.16"
    end

    test "contains environment variables" do
      server =
        Server.new(host: "example.com")
        |> Server.put_private(:conn_ref, self())

      app =
        Application.new(name: "foo")
        |> Application.set_docker_image(name: "nginx", tag: "1.16")
        |> Application.put_environment(key: "ENV", value: "prod")

      cmd = Docker.run(server, app)

      assert cmd.cmd ==
               "docker run -d --restart unless-stopped --name foo --label org.makina.app.hash=#{app.__hash__} --env ENV=prod nginx:1.16"
    end

    test "contains command arguments" do
      server =
        Server.new(host: "example.com")
        |> Server.put_private(:conn_ref, self())

      app =
        Application.new(name: "foo")
        |> Application.set_docker_image(name: "traefik", tag: "v3.3")
        |> Application.put_volume(
          source: "/var/run/docker.sock",
          destination: "/var/run/docker.sock"
        )

      app =
        app
        |> Application.set_private(:__docker__, %{
          app.__docker__
          | command: [
              "--api.insecure=true",
              "--providers.docker"
            ]
        })

      cmd = Docker.run(server, app)

      assert cmd.cmd ==
               "docker run -d --restart unless-stopped --name foo --label org.makina.app.hash=#{app.__hash__} --volume /var/run/docker.sock:/var/run/docker.sock traefik:v3.3 --api.insecure=true --providers.docker"
    end

    test "contains exposed ports" do
      server =
        Server.new(host: "example.com")
        |> Server.put_private(:conn_ref, self())

      app =
        Application.new(name: "foo")
        |> Application.set_docker_image(name: "nginx", tag: "1.16")
        |> Application.put_exposed_port(internal: 80, external: 8080)

      cmd = Docker.run(server, app)

      assert cmd.cmd ==
               "docker run -d --restart unless-stopped --name foo --label org.makina.app.hash=#{app.__hash__} -p 8080:80 nginx:1.16"
    end

    test "contains published domain as labels" do
      server =
        Server.new(host: "example.com")
        |> Server.put_private(:conn_ref, self())

      app =
        Application.new(name: "foo")
        |> Application.set_docker_image(name: "nginx", tag: "1.16")
        |> Application.put_domain("example.com")
        |> Application.set_load_balancing_port(80)

      cmd = Docker.run(server, app)

      assert cmd.cmd ==
               "docker run -d --restart unless-stopped --name foo --label org.makina.app.hash=#{app.__hash__} --label traefik.enable=true --label traefik.http.middlewares.foo.compress=true --label traefik.http.routers.foo.rule=\"Host(\\`example.com\\`)\" --label traefik.http.routers.foo.tls.certresolver=letsencrypt --label traefik.http.services.foo.loadBalancer.server.port=80 --network makina-web-net nginx:1.16"
    end
  end

  describe "stop/2" do
    test "returns the command to stop a given container" do
      app = basic_app_without_scope()

      server =
        Server.new(host: "example.com")
        |> Server.put_private(:conn_ref, self())

      cmd = Docker.stop(server, app)

      assert is_struct(cmd, RemoteCommand)

      assert cmd.cmd == "docker stop foo"
    end

    test "returns the command to stop a given container with scopes" do
      app = basic_app_with_scope()

      server =
        Server.new(host: "example.com")
        |> Server.put_private(:conn_ref, self())

      cmd = Docker.stop(server, app)

      assert is_struct(cmd, RemoteCommand)

      assert cmd.cmd == "docker stop makina_app_foo"
    end

    test "returns the command to stop an arbitrary container given a name" do
      server =
        Server.new(host: "example.com")
        |> Server.put_private(:conn_ref, self())

      cmd = Docker.stop(server, "foo_bar")

      assert is_struct(cmd, RemoteCommand)

      assert cmd.cmd == "docker stop foo_bar"
    end
  end

  describe "remove/2" do
    test "returns the command to remove the give app" do
      app = basic_app_without_scope()

      server =
        Server.new(host: "example.com")
        |> Server.put_private(:conn_ref, self())

      cmd = Docker.remove(server, app)

      assert is_struct(cmd, RemoteCommand)

      assert cmd.cmd == "docker rm foo"
    end

    test "returns the command to remove a container given its name" do
      server =
        Server.new(host: "example.com")
        |> Server.put_private(:conn_ref, self())

      cmd = Docker.remove(server, "container_name")

      assert is_struct(cmd, RemoteCommand)

      assert cmd.cmd == "docker rm container_name"
    end
  end

  describe "login/2" do
    test "returns a command to login into a private registry" do
      server =
        Server.new(host: "example.com")
        |> Server.put_private(:conn_ref, self())

      app =
        Application.new(name: "foo")
        |> Application.set_docker_registry(host: "ghcr.io", user: "user", password: "password")
        |> Application.set_docker_image(name: "nginx", tag: "1.16")

      cmd = Docker.login(server, app)

      assert is_struct(cmd, RemoteCommand)

      assert cmd.cmd == "docker login ghcr.io -u user -p password"
    end
  end

  describe "create_network/2" do
    test "returns a command to create a network with a given name" do
      server =
        Server.new(host: "example.com")
        |> Server.put_private(:conn_ref, self())

      cmd = Docker.create_network(server, "foo")

      assert is_struct(cmd, RemoteCommand)

      assert cmd.cmd == "docker network create foo"
    end
  end

  describe "inspect_network/2" do
    test "returns a command to inspect a given network" do
      server =
        Server.new(host: "example.com")
        |> Server.put_private(:conn_ref, self())

      cmd = Docker.inspect_network(server, "foo")

      assert is_struct(cmd, RemoteCommand)

      assert cmd.cmd == "docker network inspect foo"
    end
  end

  describe "rename_container/3" do
    test "returns the command to rename an app's container adding a suffix" do
      app = basic_app_without_scope()

      server =
        Server.new(host: "example.com")
        |> Server.put_private(:conn_ref, self())

      cmd = Docker.rename_container(server, app, suffix: "__stale")

      assert is_struct(cmd, RemoteCommand)

      assert cmd.cmd == "docker rename foo foo__stale"
    end
  end

  defp basic_app_without_scope() do
    Application.new(name: "foo")
  end

  defp basic_app_with_scope() do
    Application.new(name: "foo")
    |> Application.set_private(:__scope__, ["foo", :app, :makina])
  end
end
