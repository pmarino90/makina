ExUnit.configure(exclude: [:docker_client])
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Makina.Repo, :manual)
