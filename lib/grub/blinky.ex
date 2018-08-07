defmodule Grub.Blinky do
  use GenServer
  require Logger
  @idle_timeout 2_000
  @blinking_timeout 1_000

  def start_link(_), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def init(_) do
    {:ok, :idle, @idle_timeout}
  end

  def handle_info(:timeout, :idle) do
    Nerves.Leds.set(status: :fastblink)
    {:noreply, :blinking, @blinking_timeout}
  end

  def handle_info(:timeout, :blinking) do
    Nerves.Leds.set(status: false)
    {:noreply, :idle, @idle_timeout}
  end
  
  def handle_info(other, state) do
    Logger.error("#{__MODULE__} received unexpected message #{inspect(other)}")
    {:noreply, state, @idle_timeout}
  end
end
