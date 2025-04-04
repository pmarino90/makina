defmodule Makina.DSL.App do
  @moduledoc """
  Specific expressions to use inside an application block
  """

  import Makina.DSL.Utils

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
          @current_application Map.put(@current_application, :docker_image, opts)

        {:error, error} ->
          raise """
            The parameters provided to the `from_docker_image` statement are not correct:

            #{Exception.message(error)}
          """
      end
    end
  end
end
