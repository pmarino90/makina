defmodule Makina.Models.DockerTest do
  use ExUnit.Case

  alias Makina.Models.Server
  alias Makina.Models.Application

  alias Makina.Docker

  describe "inspect/2" do
    test "returns a complete command to inspect a container" do
      server =
        Server.new(host: "example.com")
        |> Server.put_private(:conn_ref, self())

      app =
        Application.new(name: "foo")
        |> Application.set_docker_image(name: "nginx", tag: "1.16")

      cmd = Docker.inspect(server, app)

      assert is_struct(cmd, Makina.Command)

      assert cmd.cmd == "docker inspect foo"
      assert cmd.server == server
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

      assert is_struct(cmd, Makina.Command)
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

      assert is_struct(cmd, Makina.Command)

      assert cmd.cmd == "docker login ghcr.io -u user -p password"
    end
  end
end
