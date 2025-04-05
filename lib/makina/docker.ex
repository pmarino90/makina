defmodule Makina.Docker do
  @doc """
  Module that contains all docker-related cli command building functions.
  On their own these do not do anything except returning a correctly formatted
  command that should then be executed over SSH.
  """
  alias Makina.Definitions.Application

  def run_command(%Application{} = app) do
    "docker run -d --restart always #{app.docker_image[:name]}"
  end
end
