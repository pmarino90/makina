defmodule Makina.DSL.Secrets do
  alias Makina.SecretProvider

  @secret_from_opts [
    environment: [
      type: :string,
      doc: """
      The environment variable's name where the secret is currently stored.
      Note: This refers to the environment in which the `makina` command is run.
      """
    ],
    "1password": [
      type: :non_empty_keyword_list,
      keys: [
        vault: [type: :string],
        account: [type: :string],
        item: [type: :string],
        field: [type: :string, default: "password"]
      ]
    ]
  ]
  @doc """
  Fetches a secret from a given provider.

  ## Supported providers:
  #{NimbleOptions.docs(@secret_from_opts)}
  """
  def secret_from(opts) do
    validation = NimbleOptions.validate(opts, @secret_from_opts)

    with {:ok, opts} <- validation,
         {provider, provider_options} <- List.first(opts),
         true <- SecretProvider.available?(provider) do
      SecretProvider.fetch_secret(provider, provider_options)
    else
      false ->
        raise """
          The requested secret provider is not available in this host.
        """

      {:error, error} ->
        raise """
          The parameters provided to `secret_for` are not correct:

          #{Exception.message(error)}
        """
    end
  end
end
