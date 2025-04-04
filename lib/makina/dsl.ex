defmodule Makina.DSL do
  alias Makina.Definitions.Server

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

  @server_opts [
    host: [type: :string, required: true],
    user: [type: :string],
    password: [type: :string],
    port: [type: :pos_integer, default: 22]
  ]

  @doc """
  Defines a server available for deploying stacks

  Multiple servers can be defined and Makina will attempt to deploy stacks in all of them.
  In order for a server to be used it has to be reacheable from the machine from where `makina` is launched.

  ## Parameters:
  #{NimbleOptions.docs(@server_opts)}
  """
  defmacro server(opts) do
    quote bind_quoted: [schema: @server_opts, opts: opts] do
      validation = NimbleOptions.validate(opts, schema)

      case validation do
        {:ok, opts} ->
          Module.put_attribute(__MODULE__, :servers, struct(Server, opts))

        {:error, error} ->
          raise """
            The parameters provided to the `server` statement are not correct:

            #{Exception.message(error)}
          """
      end
    end
  end

  defmacro standalone(do: block) do
    quote do
      Module.put_attribute(__MODULE__, :is_standalone_block?, true)
      unquote(block)
      Module.put_attribute(__MODULE__, :is_standalone_block?, false)
    end
  end

  @secret_from_opts [
    environment: [
      type: :string,
      doc: """
      The environment variable's name where the secret is currently stored.
      Note: This refers to the environment in which the `makina` command is run.
      """
    ]
  ]
  @doc """
  Fetches a secret from a given provider.

  ## Supported providers:
  #{NimbleOptions.docs(@secret_from_opts)}
  """
  def secret_from(opts) do
    validation = NimbleOptions.validate(opts, @secret_from_opts)

    case validation do
      {:ok, opts} ->
        System.get_env(opts[:environment])

      {:error, error} ->
        raise """
          The parameters provided to `secret_for` are not correct:

          #{Exception.message(error)}
        """
    end
  end

  defp define_context_attributes() do
    quote do
      Module.register_attribute(__MODULE__, :servers, accumulate: true)
      Module.register_attribute(__MODULE__, :standalone_applications, accumulate: true)
    end
  end

  defp define_support_functions() do
    quote do
      def collect_context() do
        %{
          servers: @servers,
          standalone_applications: @standalone_applications
        }
      end
    end
  end
end
