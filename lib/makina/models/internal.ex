defmodule Makina.Models.Internal do
  def hash(struct) do
    :erlang.phash2(struct)
  end
end
