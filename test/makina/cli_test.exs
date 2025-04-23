defmodule Makina.CliTest do
  use ExUnit.Case, async: true

  alias Makina.Cli

  @moduletag :tmp_dir

  describe "Command: help" do
    test "shows the help message when invoked" do
      assert :ok = Cli.command(:help)
    end
  end

  describe "Command: init" do
    test "creates a default file in the provided path", %{tmp_dir: tmp_dir} do
      assert :ok = Cli.command(:init, [tmp_dir])

      assert File.exists?(Path.join(tmp_dir, "Makinafile.exs"))
    end
  end

  describe "parse_command/1" do
    test "returns help if no command or options are provided" do
      command = Cli.parse_command([])

      assert command == {:help, [], []}
    end

    test "returns the provided command" do
      command = Cli.parse_command(["foo"])

      assert command == {:foo, [], []}
    end

    test "returns provided arguments for command" do
      command = Cli.parse_command(["foo", "./bar/"])

      assert command == {:foo, ["./bar/"], []}
    end
  end
end
