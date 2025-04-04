defmodule Makina.DSL do
  alias Makina.Definitions.Application
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
    schema = @server_opts

    quote do
      validation = NimbleOptions.validate(unquote(opts), unquote(schema))

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

  @doc """
  Defines a block of applications that are standalone

  Applications defined inside this block are deployed, or removed, in the remote server
  independently from others, this means that dependencies cannot be defined between these.

  Can be useful if you want to deploy a standalone application that doesn't have other moving pieces.

  For cases where the application might require other services (for example a webapp + a database) then `stack` is the correct option.
  """
  defmacro standalone(do: block) do
    quote do
      unquote(set_wrapping_context(:standalone))
      unquote(block)
      unquote(set_wrapping_context(nil))
    end
  end

  @app_opts [name: [type: :string, required: true]]

  @doc """
  Defines an application
  Within this block you can configure the application that you want to deploy, can be used within a `standalone` block or `stack` block.

  Depending on the context some configurations might not be available
  """
  defmacro app(opts, do: block) do
    schema = @app_opts

    quote do
      validation = NimbleOptions.validate(unquote(opts), unquote(schema))

      case validation do
        {:ok, opts} ->
          unquote(set_wrapping_context(:app))

          @current_application struct(Application, opts)

          unquote(block)

          @standalone_applications @current_application
          Module.delete_attribute(__MODULE__, :current_application)

          unquote(set_wrapping_context(nil))

        {:error, error} ->
          raise """
            The parameters provided to the `server` statement are not correct:

            #{Exception.message(error)}
          """
      end
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

  defp set_wrapping_context(nil) do
    quote do
      Module.delete_attribute(__MODULE__, :wrapping_context)
    end
  end

  defp set_wrapping_context(name) do
    quote do
      Module.put_attribute(__MODULE__, :wrapping_context, unquote(name))
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
