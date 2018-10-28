defmodule MarioAgent do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def set(who, what) do
    Agent.update(__MODULE__, &Map.put(&1, who, what))
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
