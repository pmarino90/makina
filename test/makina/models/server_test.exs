defmodule Makina.Models.ServerTest do
  use ExUnit.Case, async: true

  alias Makina.Models.Server

  describe "new/1" do
    test "creates a new server" do
      params = [host: "example.com", user: "foo"]
      server = Server.new(params)

      assert is_struct(server, Server)
      assert server.host == params[:host]
      assert server.user == params[:user]
    end
  end

  describe "put_config/2" do
    test "adds a configuration key to the server" do
      params = [host: "example.com", user: "foo"]
      server = Server.new(params)

      assert server.config == %{}

      server = Server.put_config(server, foo: "bar")

      assert server.config == %{foo: "bar"}
    end
  end

  describe "set_port/2" do
    test "sets the server's connection port" do
      params = [host: "example.com", user: "foo"]
      server = Server.new(params)

      assert server.port == 22

      server = Server.set_port(server, 12345)

      assert server.port == 12345
    end
  end

  describe "set_user/2" do
    test "sets the server's user" do
      params = [host: "example.com", user: "foo"]
      server = Server.new(params)

      assert server.user == "foo"

      server = Server.set_user(server, "bar")

      assert server.user == "bar"
    end
  end

  describe "set_password/2" do
    test "sets the server users' password" do
      params = [host: "example.com", user: "foo"]
      server = Server.new(params)

      assert server.password == nil

      server = Server.set_password(server, "bar")

      assert server.password == "bar"
    end
  end

  describe "put_private/3" do
    test "sets the server private config" do
      params = [host: "example.com", user: "foo"]
      server = Server.new(params)

      assert server.__private__ == %{}

      server = Server.put_private(server, :foo, "bar")

      assert server.__private__[:foo] == "bar"
    end
  end

  describe "connected?/1" do
    test "returns true if the provided server is connected" do
      params = [host: "example.com", user: "foo"]

      server =
        Server.new(params)
        |> Server.put_private(:conn_ref, self())

      assert Server.connected?(server) == true
    end

    test "returns false if the provided server is not connected" do
      params = [host: "example.com", user: "foo"]

      assert Server.connected?(Server.new(params)) == false

      server = Server.new(params) |> Server.put_private(:conn_ref, nil)

      assert Server.connected?(server) == false

      server = Server.new(params) |> Server.put_private(:foo, "bar")

      assert Server.connected?(server) == false
    end
  end
end
