defmodule Makina.Models.Internal do
  def hash(struct) do
    struct
    |> :erlang.term_to_binary()
    |> :erlang.phash2()
  end
end
