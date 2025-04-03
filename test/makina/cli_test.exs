defmodule Makina.CliTest do
  use ExUnit.Case

  alias Makina.Cli

  describe "Command: help" do
    test "shows the help message when invoked" do
      {:ok, response} = Cli.command(:help)

      assert response =~ "Usage"
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
  end
end
