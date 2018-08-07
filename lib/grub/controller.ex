defmodule Grub.Controller do
  use Supervisor
  alias ElixirALE.GPIO

  # pass zone info here
  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(arg) do
    # supervise zones here
    zones = [
    ]
    Supervisor.init(zones, strategy: :one_for_one)
  end
end
