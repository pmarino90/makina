defmodule Makina.DSL do
  import Makina.DSL.Utils

  alias Makina.Models.Application
  alias Makina.Models.Server
  alias Makina.Models.Context

  @doc """
  Toplevel expression used to define a Makinafile
  """
  defmacro makina(id, do: block) do
    module_name = "User.MakinaFile.#{id}" |> String.to_atom()

    quote do
      defmodule unquote(module_name) do
        @context_id unquote(id)
        unquote(define_context_attributes())
        unquote(set_scope([:makina, id]))
        unquote(block)
        unquote(define_support_functions())
      end
    end
  end

  @server_opts [
    host: [type: :string, required: true],
    user: [type: :string],
    password: [type: :string],
    port: [type: :pos_integer, default: 22],
    config: [type: :keyword_list]
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
          Module.put_attribute(__MODULE__, :servers, Server.new(opts))

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
      unquote(set_scope(:standalone))
      unquote(block)
    end
  end

  @app_opts [name: [type: :string, required: true]]

  @doc """
  Defines an application
  Within this block you can configure the application that you want to deploy, can be used within a `standalone` block or `stack` block.

  Depending on the context some configurations might not be available
  """

  defmacro app(opts, do: block) when is_list(opts) do
    schema = @app_opts

    quote do
      validation = NimbleOptions.validate(unquote(opts), unquote(schema))

      case validation do
        {:ok, opts} ->
          import Makina.DSL.App

          unquote(set_scope([:app, opts[:name]]))

          @current_application Application.new(opts)
                               |> Application.set_private(:__scope__, @scope)

          unquote(block)

          @standalone_applications @current_application
          Module.delete_attribute(__MODULE__, :current_application)

        {:error, error} ->
          raise """
            The parameters provided to the `app` statement are not correct:

            #{Exception.message(error)}
          """
      end
    end
  end

  defmacro app(opts, do: _block) when is_binary(opts) do
    raise """
    Invalid block definition for `app`.

    A correct block definition is like so:
        app name: "my_app" do

        end
    """
  end

  def app(_opts) do
    raise """
    Invalid block definition for `app`.

    A correct block definition is like so:
        app name: "my_app" do

        end
    """
  end

  defdelegate secret_from(opts), to: Makina.DSL.Secrets

  defp define_context_attributes() do
    quote do
      Module.register_attribute(__MODULE__, :scope, accumulate: true)
      Module.register_attribute(__MODULE__, :servers, accumulate: true)
      Module.register_attribute(__MODULE__, :standalone_applications, accumulate: true)
    end
  end

  defp define_support_functions() do
    quote do
      def collect_context() do
        Context.new(
          id: @context_id,
          servers: @servers,
          standalone_applications: @standalone_applications
        )
      end
    end
  end
end
