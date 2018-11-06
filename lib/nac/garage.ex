defmodule NAC.GarageDoor do
  alias ElixirALE.GPIO

  defstruct id: nil, sensor: nil, opener: nil

  def create(id, opener_gpio, sensor_gpio) do
    {:ok, opener} = GPIO.start_link(opener_gpio, :output)
    {:ok, sensor} = GPIO.start_link(sensor_gpio, :input)

    %__MODULE__{id: id, opener: opener, sensor: sensor}
  end
end
