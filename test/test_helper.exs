Mox.defmock(TestRemoteCommandExecutor, for: Makina.Infrastructure.RemoteCommand.Executor)
Application.put_env(:makina, :remote_command_executor, TestRemoteCommandExecutor)

ExUnit.start()
