defmodule Makina.Docker do
  @doc """
  Module that contains all docker-related cli command building functions.
  On their own these do not do anything except returning a correctly formatted
  command that should then be executed over SSH.
  """
  alias Makina.Models.Server
  alias Makina.Models.Application

  def run_command(%Server{} = server, %Application{} = app) do
    docker_path = Keyword.get(server.config, :docker_path, nil)

    "#{docker_path}docker run -d --restart always #{app.docker_image[:name]}"
  end
end
