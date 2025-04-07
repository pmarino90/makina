defmodule Makina.DSL.Utils do
  @moduledoc false

  def unset_wrapping_context() do
    quote do
      Module.delete_attribute(__MODULE__, :wrapping_context)
    end
  end

  def set_scope(scope) when is_list(scope) do
    for s <- scope do
      set_scope(s)
    end
  end

  def set_scope(scope) do
    quote do
      @scope unquote(scope)
    end
  end
end
