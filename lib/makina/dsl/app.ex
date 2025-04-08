defmodule Makina.DSL.App do
  @moduledoc """
  Specific expressions to use inside an application block
  """

  alias Makina.Models.Application

  @from_docker_image_opts [
    name: [type: :string, required: true],
    tag: [type: :string, default: "latest"]
  ]

  @doc """
  Configures the given app to be created from an existing docker image.

  ## Parameters
  """
  defmacro from_docker_image(opts) do
    schema = @from_docker_image_opts

    quote do
      validation = NimbleOptions.validate(unquote(opts), unquote(schema))

      case validation do
        {:ok, opts} ->
          @current_application Application.set_docker_image(@current_application, opts)

        {:error, error} ->
          raise """
            The parameters provided to the `from_docker_image` statement are not correct:

            #{Exception.message(error)}
          """
      end
    end
  end

  @doc """
  Mounts a volume to the given app.

  ## Usage
  ```elixir
  makina "example" do
    app name: "foo" do

    volume "source", "destination"

    end
  end
  ```
  """
  defmacro volume(source, destination) when is_binary(source) and is_binary(destination) do
    quote bind_quoted: [source: source, destination: destination] do
      @current_application Application.put_volume(@current_application,
                             source: source,
                             destination: destination
                           )
    end
  end

  @doc """
  Exposes a port on the given app

  ## Usage
  ```elixir
  makina "example" do
    app name: "foo" do

    # expose_port <internal port>, <external port>
    expose_port 8080, 80

    end
  end
  ```
  """
  defmacro expose_port(internal, external)
           when is_number(internal) and is_number(external) do
    quote bind_quoted: [internal: internal, external: external] do
      @current_application Application.put_exposed_port(@current_application,
                             internal: internal,
                             external: external
                           )
    end
  end
end
