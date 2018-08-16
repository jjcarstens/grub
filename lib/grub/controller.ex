defmodule Grub.Controller do
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

  def available_zones(node_or_supervisor \\ Grub.Supervisor) do
    children = Supervisor.which_children(node_or_supervisor)

    for {"ZONE_" <> zone_str, pid, _, _} <- children do
      {zone_num, _} = Integer.parse(zone_str)
      {zone_num, pid}
    end
  end

  def toggle_zone(zone, :off), do: Logger.info("ZONE #{zone} off")
  def toggle_zone(zone, :on), do: Logger.info("ZONE #{zone} on")

  def handle_call({:toggle_zone, zone, :on}, _from, state) do
    Logger.info("ZONE #{zone} on")
    {:reply, :ok, state}
  end
  def handle_call({:toggle_zone, zone, :off}, _from, state) do
    Logger.info("ZONE #{zone} off")
    {:reply, :ok, state}
  end

  def handle_info(:init_zones, state) do
    zones = Application.get_env(:grub, :gpio_to_zone_mapping)
    |> Enum.reduce(%{}, fn %{zone: zone, gpio: gpio}, acc ->
      child_spec = %{id: :"GPIO_#{gpio}_ZONE_#{zone}", start: {GPIO, :start_link, [gpio, :output]}}
      {:ok, pid} = Supervisor.start_child(Grub.Supervisor, child_spec)
      GPIO.write(pid, 1) # Ensure zone is off
      Map.put(acc, zone, pid)
    end)


    {:noreply, Map.put(state, :zones, zones)}
  end
end
