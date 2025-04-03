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
end
