defmodule Grub.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @target Mix.Project.config()[:target]

  use Application

  def start(_type, _args) do
    children(:default)
    |> Enum.concat(children(@target))
    |> Supervisor.start_link(strategy: :one_for_one, name: Grub.Supervisor)
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
      {Grub.Blinky, nil},
      {Grub.Controller, []}
    ] ++ zones()
  end

  defp zones do
    Application.get_env(:grub, :gpio_to_zone_mapping)
    |> Enum.map(fn %{zone: zone, gpio: gpio} ->
      %{id: "ZONE_#{zone}_GPIO_#{gpio}", start: {ElixirALE.GPIO, :start_link, [gpio, :output, [start_value: 1, name: {:via, Registry, {Registry.Zone, zone}}]]}}
    end)
  end
end
