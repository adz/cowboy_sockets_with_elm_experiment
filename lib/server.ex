defmodule Server do
  use Application
  require Logger

  @port 8080

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Server.Router, [],
        dispatch: dispatch(),
        port: @port
      ),
      MarioAgent
    ]

    Logger.info("Started weirdness on port #{@port}")
    opts = [strategy: :one_for_one, name: Navis.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {:_,
       [
         {"/ws", Server.SocketHandler, []},
         {:_, Plug.Adapters.Cowboy.Handler, {Server.Router, []}}
       ]}
    ]
  end
end
