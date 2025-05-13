defmodule Makina.Models.ApplicationTest do
  use ExUnit.Case, async: true

  alias Makina.Models.Application

  describe "new/1" do
    test "creates a new application given its parameters" do
      params = [name: "foo", docker_image: [name: "foo", tag: "latest"]]

      app = Application.new(params)

      assert is_struct(app, Application)
      assert app.name == params[:name]

      refute is_nil(app.__hash__)
    end
  end

  describe "put_volume/2" do
    test "adds a volume to the current application" do
      params = [name: "foo", docker_image: [name: "foo", tag: "latest"]]

      app = Application.new(params)
      init_hash = app.__hash__

      assert app.volumes == []

      app = app |> Application.put_volume(source: "source", destination: "dest")

      assert app.volumes == [%{source: "source", destination: "dest"}]
      assert app.__hash__ != init_hash
    end
  end

  describe "set_docker_image/2" do
    test "sets the docker image for the application" do
      params = [name: "foo"]

      app = Application.new(params)
      init_hash = app.__hash__

      assert app.docker_image == nil

      app = app |> Application.set_docker_image(name: "foo", tag: "latest")

      assert app.docker_image == %{name: "foo", tag: "latest"}
      assert app.__hash__ != init_hash
    end

    test "setting docker_image when a dockerfile is present raises an error" do
      params = [name: "foo"]

      app = Application.new(params)

      app =
        app
        |> Application.set_dockerfile(name: "Dockerfile", tag: "foo")

      assert catch_error(Application.set_docker_image(app, name: "foo", tag: "latest"))
    end
  end

  describe "set_dockerfile/2" do
    test "sets dockerfile info" do
      params = [name: "foo"]

      app = Application.new(params)
      init_hash = app.__hash__

      assert app.dockerfile == nil

      app = app |> Application.set_dockerfile(name: "Dockerfile", context: ".", tag: "latest")

      assert app.dockerfile == %{name: "Dockerfile", tag: "latest", context: "."}
      assert app.__hash__ != init_hash
    end

    test "setting dockerfile when a docker image is present raises an error" do
      params = [name: "foo"]

      app = Application.new(params)

      app =
        app
        |> Application.set_docker_image(name: "foo", tag: "latest")

      assert catch_error(Application.set_dockerfile(app, name: "Dockerfile", tag: "foo"))
    end
  end

  describe "set_docker_registry/2" do
    test "sets the docker registry with credentials" do
      params = [name: "foo"]

      app = Application.new(params)
      init_hash = app.__hash__

      assert app.docker_image == nil

      app =
        app
        |> Application.set_docker_registry(host: "ghcr.io", user: "foo", password: "bar")

      assert app.docker_registry == %{
               host: "ghcr.io",
               user: "foo",
               password: "bar"
             }

      assert app.__hash__ != init_hash
    end
  end

  describe "put_environment/2" do
    test "adds environment variables to the application" do
      params = [name: "foo"]

      app = Application.new(params)
      init_hash = app.__hash__

      assert app.env_vars == []

      app = app |> Application.put_environment(key: "key", value: "value")

      assert app.env_vars == [%{key: "key", value: "value"}]
      assert app.__hash__ != init_hash
    end
  end

  describe "put_exposed_port/2" do
    test "adds an exposed port pair to the list" do
      params = [name: "foo"]

      app = Application.new(params)
      init_hash = app.__hash__

      assert app.env_vars == []

      app = app |> Application.put_exposed_port(internal: 80, external: 8080)

      assert app.exposed_ports == [%{internal: 80, external: 8080}]
      assert app.__hash__ != init_hash
    end
  end

  describe "put_domain/2" do
    test "adds an exposed port pair to the list" do
      params = [name: "foo"]

      app = Application.new(params)
      init_hash = app.__hash__

      app = app |> Application.put_domain("example.com")

      assert app.domains == ["example.com"]
      assert app.__hash__ != init_hash
    end
  end

  describe "set_load_balancing_port/2" do
    test "sets the port used by the proxy load balancer" do
      params = [name: "foo"]

      app = Application.new(params)
      init_hash = app.__hash__

      app = app |> Application.set_load_balancing_port(8080)

      assert app.load_balancing_port == 8080
      assert app.__hash__ != init_hash
    end
  end

  describe "set_privileged/2" do
    test "defaults to false unless set" do
      params = [name: "foo"]

      app = Application.new(params)

      assert app.privileged? == false
    end

    test "sets if the applications should run as priviledged" do
      params = [name: "foo"]

      app = Application.new(params)
      init_hash = app.__hash__

      app = app |> Application.set_privileged(true)

      assert app.privileged? == true
      assert app.__hash__ != init_hash
    end
  end

  describe "set_private/3" do
    test "sets private fields" do
      params = [name: "foo"]

      app = Application.new(params)
      init_hash = app.__hash__

      assert app.__scope__ == []

      assert app.__docker__ == %{
               command: [],
               labels: [],
               networks: []
             }

      app = Application.set_private(app, :__scope__, [:foo])

      assert app.__scope__ == [:foo]
      assert app.__hash__ == init_hash
    end
  end
end
