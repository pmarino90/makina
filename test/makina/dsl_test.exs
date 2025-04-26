defmodule Makina.DSLTest do
  use ExUnit.Case, async: true

  alias Makina.DSL

  describe "makina/1" do
    test "defines a custom module representing a makinafile" do
      import DSL

      term =
        makina "foo" do
        end

      assert elem(term, 0) == :module
      assert elem(term, 1) |> Atom.to_string() =~ "User.MakinaFile"

      mod = elem(term, 1)

      assert Kernel.function_exported?(mod, :collect_context, 0)

      context = mod.collect_context()

      assert context.id == "foo"
    end
  end

  describe "server/1" do
    test "sets a server into the Makinafile context" do
      import DSL

      term =
        makina "test-server-dsl" do
          server host: "example.com", user: "user"
        end

      module = elem(term, 1)
      context = module.collect_context()

      assert Map.has_key?(context, :servers)
      assert Enum.count(context.servers) == 1
    end
  end

  describe "app/2" do
    test "allow setting docker image config" do
      import DSL

      term =
        makina "app-test-allow-docker-image" do
          app name: "test" do
            from_docker_image name: "name", tag: "tag"
          end
        end

      module = elem(term, 1)
      context = module.collect_context()

      app = List.first(context.applications)

      assert app.docker_image[:name] == "name"
      assert app.docker_image[:tag] == "tag"
    end

    test "allow volumes to be specified" do
      import DSL

      term =
        makina "app-test-specify-module" do
          app name: "test" do
            volume "foo", "/app/data"
          end
        end

      module = elem(term, 1)
      context = module.collect_context()

      app = List.first(context.applications)

      assert is_list(app.volumes)

      volume = List.first(app.volumes)

      assert volume == %{source: "foo", destination: "/app/data"}
    end

    test "allow exposed port to be specified" do
      import DSL

      term =
        makina "app-test-specify-port" do
          app name: "test" do
            expose_port 8080, 80
          end
        end

      module = elem(term, 1)
      context = module.collect_context()

      app = List.first(context.applications)

      assert is_list(app.exposed_ports)

      port = List.first(app.exposed_ports)

      assert port == %{internal: 80, external: 8080}
    end

    test "lets the user expose an app with domains" do
      import Makina.DSL

      term =
        makina "app-test-specify-domain" do
          app name: "test" do
            publish_on_domain(["example.com"], from_port: 80)
          end
        end

      module = elem(term, 1)
      context = module.collect_context()

      app = List.first(context.applications)

      assert is_list(app.domains)

      assert app.domains == ["example.com"]
      assert app.load_balancing_port == 80
    end

    test "raises if app block is not invoked correctly" do
      import DSL

      catch_error(
        makina "error-test-app" do
          app("test")
        end
      )

      catch_error(
        makina "error-test-app-2" do
          app "test" do
          end
        end
      )
    end
  end

  describe "secret_for/1" do
    test "returns a secret stored in an environment variable" do
      System.put_env("FOO", "secret")

      secret = DSL.secret_from(environment: "FOO")

      assert secret == "secret"
    end
  end
end
