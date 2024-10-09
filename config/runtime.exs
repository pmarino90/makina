import Config
import Dotenvy

source!([".env", System.get_env()])

if System.get_env("PHX_SERVER") do
  config :makina, MakinaWeb.Endpoint, server: true
end

config :makina, Makina.Runtime,
  enable_https: env!("RUNTIME_ENABLE_HTTPS", :boolean, "true"),
  reverse_proxy: [letsencrypt_email: "foo@bar.ext", acme_file_path: "./acme.json"]

config :makina, Makina.Docker, socket_path: env!("RUNTIME_DOCKER_SOCKET_PATH", :string!)

if config_env() == :prod do
  database_path =
    env!("DATABASE_PATH", :string!)

  config :makina, Makina.Repo,
    database: database_path,
    pool_size: env!("POOL_SIZE", :integer, "5")

  secret_key_base = env!("SECRET_KEY_BASE", :string!)

  port = env!("PORT", :integer, "4000")

  config :makina, :dns_cluster_query, env!("DNS_CLUSTER_QUERY", :string?)

  config :makina, MakinaWeb.Endpoint,
    url: [host: nil, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  makina_vault_key = env!("MAKINA_VAULT_CURRENT_KEY", :string!)

  config :makina, Makina.Vault,
    ciphers: [
      default: {
        Cloak.Ciphers.AES.GCM,
        tag: "AES.GCM.V1", key: Base.decode64!(makina_vault_key), iv_length: 12
      }
    ]
end
