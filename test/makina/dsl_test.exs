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

  describe "secret_for/1" do
    test "returns a secret stored in an environment variable" do
      System.put_env("FOO", "secret")

      secret = DSL.secret_from(environment: "FOO")

      assert secret == "secret"
    end
  end
end
