defmodule Makina.FileTest do
  use ExUnit.Case

  alias Makina.File

  describe "read_makina_file!/1" do
    test "reads a makina file given its path and return the string content" do
      build_file = Path.expand("../support/fixtures/test_build_file.exs", __DIR__)

      content = File.read_makina_file!(build_file)

      refute is_nil(content)
      assert content =~ "# hello"
    end
  end

  describe "evaluate_makina_file/1" do
    test "evaluates an empty Makina file successfully" do
      file = """
      """

      {term, bindings} = File.evaluate_makina_file(file)

      assert is_nil(term)
      assert bindings == []
    end

    test "ensure that Makina.DSL is automatically imported" do
      file = """
      makina do

      end
      """

      {term, bindings} = File.evaluate_makina_file(file)

      refute is_nil(term)
      assert Atom.to_string(elem(term, 1)) =~ "User.MakinaFile."
      assert bindings == []
    end
  end

  describe "collect_makina_file_context/1" do
    test "returns a map with all collected info from a Makinafile" do
      file = """
      makina do

      end
      """

      context = File.evaluate_makina_file(file) |> File.collect_makina_file_context()

      assert is_map(context)
    end
  end
end
