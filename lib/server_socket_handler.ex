defmodule Server.SocketHandler do
  @behaviour :cowboy_websocket_handler

  def handle_change do
  end

  def init(_, _req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  # terminate if no activity for one minute
  @timeout 60000

  # Called on websocket connection initialization.
  def websocket_init(_type, req, _opts) do
    state = %{}

    MarioAgent.add_client(self())

    MarioAgent.get_clients()
    |> IO.inspect()

    {:ok, req, state, @timeout}
  end

  def websocket_handle({:text, message}, req, state) do
    mario =
      message
      |> Poison.decode!()

    IO.puts("INCOMING MARIO")
    IO.inspect(mario)

    {cid, req2} = :cowboy_req.header("sec-websocket-key", req)

    # Put this mario in
    MarioAgent.set(cid, mario)

    # Get all the marios
    everyone =
      MarioAgent.get()
      |> Poison.encode!()

    # Get all the browsers, and send them all the marios
    MarioAgent.get_clients()
    |> Enum.each(fn a -> send(a, everyone) end)

    {:ok, req2, state}
  end

  # Format and forward elixir messages to client
  def websocket_info(message, req, state) do
    {:reply, {:text, message}, req, state}
  end

  # No matter why we terminate, remove all of this pids subscriptions
  def websocket_terminate(_reason, req, _state) do
    {cid, req2} = :cowboy_req.header("sec-websocket-key", req)

    MarioAgent.kill(cid)

    MarioAgent.remove_client(self())

    MarioAgent.get_clients()
    |> IO.inspect()

    :ok
  end
end
