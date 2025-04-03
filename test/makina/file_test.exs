defmodule Makina.FileTest do
  use ExUnit.Case

  alias Makina.File

  describe "compile_build_file/1" do
    test "returns bindings defined into the buildfile given its path" do
      build_file = Path.expand("../support/fixtures/test_build_file.exs", __DIR__)

      bindings = File.compile_build_file(build_file)

      assert is_list(bindings)
    end
  end

  describe "fetch_servers/1" do
    test "returns empty list if not servers are defined" do
      servers = File.fetch_servers()

      assert servers == []
    end

    test "returns all servers defined inside the file" do
      build_file = Path.expand("../support/fixtures/file_with_servers.exs", __DIR__)
      File.compile_build_file(build_file)

      servers = File.fetch_servers()

      assert Enum.count(servers) == 2
      assert Map.get(List.first(servers), :host) == "example.com"
    end
  end
end
