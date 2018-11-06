defmodule NAC.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @target Mix.Project.config()[:target]
  @leds %{"a" => "led0", "b" => "led1"}

  use Application

  def start(_type, _args) do
    children(:default)
    |> Enum.concat(children(@target))
    |> Supervisor.start_link(strategy: :one_for_one, name: NAC.Supervisor)
  end

  def start_phase(:start_led, _, _) do
    if @target == "rpi3" do
      Nerves.Led.set("led1", false) # turn off power LED
      led = Map.get(@leds, Nerves.Runtime.KV.get("nerves_fw_active"))
      Nerves.Led.set(led, true) # set LED according to A or B partition
    end

    :ok
  end
  # List all child processes to be supervised
  def children(:default) do
    [
      {Registry, keys: :unique, name: Registry.Zone}
    ]
  end

  def children("host") do
    []
  end

  def children(_target) do
    [
      {NAC.Controller, []},
      {NAC.GarageController, %{}}
    ] ++ zones()
  end

  defp zones do
    Application.get_env(:nac, :gpio_to_zone_mapping)
    |> Enum.map(fn %{zone: zone, gpio: gpio} ->
      %{id: "ZONE_#{zone}_GPIO_#{gpio}", start: {ElixirALE.GPIO, :start_link, [gpio, :output, [start_value: 1, name: {:via, Registry, {Registry.Zone, zone}}]]}}
    end)
  end
end
