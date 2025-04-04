defmodule Makina.DSLTest do
  use ExUnit.Case

  alias Makina.DSL

  describe "makina/1" do
    test "defines a custom module representing a makinafile" do
      import DSL

      term =
        makina do
        end

      assert elem(term, 0) == :module
      assert elem(term, 1) |> Atom.to_string() =~ "User.MakinaFile"

      mod = elem(term, 1)

      assert Kernel.function_exported?(mod, :collect_context, 0)
    end
  end

  describe "server/1" do
    test "sets a server into the Makinafile context" do
      import DSL

      term =
        makina do
          server host: "example.com", user: "user"
        end

      module = elem(term, 1)
      context = module.collect_context()

      assert Map.has_key?(context, :servers)
      assert Enum.count(context[:servers]) == 1
    end
  end

  describe "standalone/1" do
    test "returns an empty list of applications when the block is empty" do
      import DSL

      term =
        makina do
          standalone do
          end
        end

      module = elem(term, 1)
      context = module.collect_context()

      assert Map.has_key?(context, :standalone_applications)
      assert context[:standalone_applications] == []
    end

    test "collects apps defined inside the block" do
      import DSL

      term =
        makina do
          standalone do
            app name: "test" do
            end
          end
        end

      module = elem(term, 1)
      context = module.collect_context()

      assert Map.has_key?(context, :standalone_applications)

      assert List.first(context[:standalone_applications])
             |> is_struct(Makina.Definitions.Application)
    end
  end

  describe "app/2" do
    test "allow setting docker image config" do
      import DSL

      term =
        makina do
          standalone do
            app name: "test" do
              from_docker_image name: "name", tag: "tag"
            end
          end
        end

      module = elem(term, 1)
      context = module.collect_context()

      app = List.first(context[:standalone_applications])

      assert app.docker_image[:name] == "name"
      assert app.docker_image[:tag] == "tag"
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
