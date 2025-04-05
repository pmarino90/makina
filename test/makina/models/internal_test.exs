defmodule Makina.Models.InternalTest do
  use ExUnit.Case

  alias Makina.Models.Server
  alias Makina.Models.Internal

  describe "hash/1" do
    test "generates an hash of a given model" do
      struct = Server.new(host: "123", user: "user")

      hash = Internal.hash(struct)

      refute is_nil(hash)
    end

    test "same struct, different key order returns the same hash" do
      struct1 = %Server{user: "user", host: "host"}
      struct2 = %Server{host: "host", user: "user"}

      hash1 = Internal.hash(struct1)
      hash2 = Internal.hash(struct2)

      assert hash1 == hash2
    end
  end
end
