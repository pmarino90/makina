defmodule Makina.DSL do
  alias Makina.Definitions.Server

  @server_opts [
    host: [type: :string, required: true],
    user: [type: :string],
    password: [type: :string],
    port: [type: :pos_integer, default: 22]
  ]

  @doc """
  Toplevel expression used to define a Makinafile
  """
  defmacro makina(do: block) do
    module_name = "User.MakinaFile.#{DateTime.utc_now()}" |> String.to_atom()

    quote do
      defmodule unquote(module_name) do
        unquote(define_context_attributes())
        unquote(block)
        unquote(define_support_functions())
      end
    end
  end

  @doc """
  Defines a server available for deploying stacks

  Multiple servers can be defined and Makina will attempt to deploy stacks in all of them.
  In order for a server to be used it has to be reacheable from the machine from where `makina` is launched.
  """
  defmacro server(opts) do
    validation = NimbleOptions.validate(opts, @server_opts)

    case validation do
      {:ok, opts} ->
        quote do
          Module.put_attribute(__MODULE__, :servers, struct(Server, unquote(opts)))
        end

      {:error, error} ->
        raise """
          The parameters provided to the `server` statement are not correct:

          #{Exception.message(error)}
        """
    end
  end

  defmacro stack(opts, do: block) do
    quote do
      @stack_name unquote(opts[:name])
      unquote(block)
      Module.delete_attribute(__MODULE__, :stack_name)
    end
  end

  defp define_context_attributes() do
    quote do
      Module.register_attribute(__MODULE__, :servers, accumulate: true)
    end
  end

  defp define_support_functions() do
    quote do
      def collect_context() do
        %{
          servers: @servers
        }
      end
    end
  end
end
