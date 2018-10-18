defmodule Grub.GarageController do
  use GenServer
  alias ElixirALE.GPIO
  alias Grub.GarageDoor

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    send self(), :init
    {:ok, state}
  end

  def available_doors(controller) do
    GenServer.call(controller, :available_doors)
  end

  def trigger(controller, garage_id) do
    GenServer.call(controller, {:trigger, garage_id})
  end

  def status(controller, garage_id) do
    GenServer.call(controller, {:status, garage_id})
  end

  def handle_call({:status, garage_id}, _from, state) do
    door = Enum.find(state.doors, &(&1.id == garage_id))
    status = case GPIO.read(door.sensor) do
               0 -> :closed
               1 -> :open
             end

    {:reply, status, state}
  end

  def handle_call({:trigger, garage_id}, _from, state) do
    door = Enum.find(state.doors, &(&1.id == garage_id))
    GPIO.write(door.opener, 1)
    :timer.sleep(500) # give it a half-second to keep up with the trigger
    GPIO.write(door.opener, 0)
    {:reply, :ok, state}
  end

  def handle_call(:available_doors, _from, state) do
    {:reply, state.doors, state}
  end

  def handle_info(:init, state) do
    west = GarageDoor.create("west", 17, 16)
    east = GarageDoor.create("east", 27, 12)

    {:noreply, Map.put(state, :doors, [east, west])}
  end
end
