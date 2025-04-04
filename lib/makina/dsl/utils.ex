defmodule Makina.DSL.Utils do
  @moduledoc false

  def set_wrapping_context(nil) do
    quote do
      Module.delete_attribute(__MODULE__, :wrapping_context)
    end
  end

  def set_wrapping_context(name) do
    quote do
      Module.put_attribute(__MODULE__, :wrapping_context, unquote(name))
    end
  end
end
