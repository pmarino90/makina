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

  def pop_scope(amount) do
    quote do
      scope = Enum.drop(@scope, unquote(amount))

      Module.delete_attribute(__MODULE__, :scope)

      for s <- Enum.reverse(scope) do
        @scope s
      end
    end
  end
end
