defmodule NAC.SprinklerController do
  use GenServer
  alias ElixirALE.GPIO

  require Logger

  # pass zone info here
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  ##
  # Client API
  #
  def available_zones(node_or_supervisor \\ NAC.Supervisor) do
    children = Supervisor.which_children(node_or_supervisor)

    for {<<"ZONE_", zone_str::bytes-size(1), _::binary>>, pid, _, _} <- children do
      {zone_num, _} = Integer.parse(zone_str)
      {zone_num, pid}
    end
  end

  def read_zone(zone) when is_integer(zone) do
    zone_via_tuple(zone)
    |> GenServer.whereis
    |> read_zone()
  end

  def read_zone(zone) when is_pid(zone) do
    case GPIO.read(zone) do
      0 -> :on
      _ -> :off
    end
  end

  def read_zone(_zone), do: {:error, %ArgumentError{message: "bad zone"}}

  def read_zone(controller, zone) do
    GenServer.call(controller, {:read_zone, zone})
  end

  def toggle_zone(zone, value) when is_pid(zone) do
    case validate_zone_value(value) do
      {:ok, value} -> GPIO.write(zone, value)
      error -> error
    end
  end

  def toggle_zone(zone, value) when is_integer(zone) do
    zone_via_tuple(zone)
    |> GenServer.whereis
    |> toggle_zone(value)
  end

  def toggle_zone(_zone, _value), do: {:error, %ArgumentError{message: "bad zone"}}

  def toggle_zone(controller, zone, value) do
    GenServer.call(controller, {:toggle_zone, zone, value})
  end

  def zone_via_tuple(zone_num), do: {:via, Registry, {Registry.Zone, zone_num}}

  ##
  # Callbacks
  #
  def handle_call({:toggle_zone, zone, value}, _from, state) do
    {:reply, toggle_zone(zone, value), state}
  end

  def handle_call({:read_zone, zone}, _from, state) do
    {:reply, read_zone(zone), state}
  end

  def handle_cast({:default_run, zone_time}, state) do
    zones = available_zones() |> Keyword.values() |> Enum.reverse
    Enum.reduce(zones, nil, fn zone, current ->
      ensure_zone_toggled(current, :off)
      ensure_zone_toggled(zone, :on)
      :timer.sleep(zone_time)
      zone
    end)
    |> ensure_zone_toggled(:off)

    {:noreply, state}
  end

  defp ensure_zone_toggled(zone, toggle) when is_pid(zone) or is_integer(zone) do
    case read_zone(zone) do
      ^toggle -> :ok
      _ ->
        toggle_zone(zone, toggle)
        ensure_zone_toggled(zone, toggle)
    end
  end
  defp ensure_zone_toggled(_zone, _toggle), do: {:error, %ArgumentError{message: "No zone to toggle"}}

  defp validate_zone_value(value) when value in [1, :off, false], do: {:ok, 1}
  defp validate_zone_value(value) when value in [0, :on, true], do: {:ok, 0}
  defp validate_zone_value(_value), do: {:error, %ArgumentError{message: "invalid zone value"}}
end
