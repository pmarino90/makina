defmodule Makina.Models.Context do
  @doc """
  Represents the context of a Makinafile
  """
  defstruct id: nil, servers: [], standalone_applications: []

  def new(opts) do
    struct(__MODULE__, opts)
  end
end
