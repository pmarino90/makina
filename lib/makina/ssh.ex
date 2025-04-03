defmodule Makina.SSH do
  @moduledoc """
  Thin wrapper around Erlang's :ssh
  """

  @connect_opts [
    port: [
      type: :integer,
      default: 22
    ],
    user: [type: :string, required: true],
    password: [type: :string]
  ]

  @doc """
  Connects to a given host over SSH provided the following options:
  #{NimbleOptions.docs(@connect_opts)}
  """
  def connect(host, opts) when is_list(opts) do
    opts = NimbleOptions.validate!(opts, @connect_opts)

    :ssh.connect(String.to_charlist(host), opts[:port],
      user: String.to_charlist(opts[:user]),
      password: String.to_charlist(opts[:password]),
      silently_accept_hosts: true
    )
  end

  @doc """
  Disconnects from a server, requires the connection reference.
  """
  def disconnect(connection_ref) do
    :ssh.close(connection_ref)
  end
end
