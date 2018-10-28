defmodule MarioAgent do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  # Mario comes in with dx/dy for x/y
  def set(who, mario) do
    Agent.update(
      __MODULE__,
      fn state ->
        IO.puts("1")

        oldMario =
          state[who]
          |> IO.inspect()

        IO.puts("2")

        newMario =
          if is_nil(oldMario) do
            IO.puts("its a new me")
            mario
          else
            IO.puts("its a old me")

            mario
            |> Map.update("x", mario["x"], fn dX -> dX + oldMario["x"] end)
            |> Map.update("y", mario["y"], fn dY -> dY + oldMario["y"] end)
          end

        Map.put(state, who, newMario)
      end
    )
  end

  def add_client(pid) do
    Agent.update(__MODULE__, &Map.update(&1, "pids", [pid], fn pids -> [pid | pids] end))
  end

  def remove_client(pid) do
    Agent.update(__MODULE__, &Map.update(&1, "pids", [], fn pids -> pids |> List.delete(pid) end))
  end

  def get_clients() do
    Agent.get(__MODULE__, &(&1 |> Map.get("pids")))
  end

  def kill(who) do
    Agent.update(__MODULE__, &Map.delete(&1, who))
  end

  def get do
    Agent.get(__MODULE__, & &1)
    |> Map.delete("pids")
  end
end
