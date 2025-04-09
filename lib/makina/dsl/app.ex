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

  @docker_registry_opts [
    host: [type: :string, required: true],
    user: [type: :string, required: true],
    password: [type: :string, required: true]
  ]

  defmacro docker_registry(opts) do
    schema = @docker_registry_opts

    quote do
      validation = NimbleOptions.validate(unquote(opts), unquote(schema))

      case validation do
        {:ok, opts} ->
          @current_application Application.set_docker_registry(@current_application, opts)

        {:error, error} ->
          raise """
            The parameters provided to the `docker_registry` statement are not correct:

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
  defmacro expose_port(external, internal) do
    quote bind_quoted: [internal: internal, external: external] do
      @current_application Application.put_exposed_port(@current_application,
                             internal: internal,
                             external: external
                           )
    end
  end

  @doc """
    Adds an environment variable to the running application

  ## Usage
  ```elixir
  makina "example" do
    app name: "foo" do

    env "FOO", "BAR"

    end
  end
  ```
  """
  defmacro env(key, value) do
    quote bind_quoted: [key: key, value: value] do
      @current_application Application.put_environment(@current_application,
                             key: key,
                             value: value
                           )
    end
  end
end
