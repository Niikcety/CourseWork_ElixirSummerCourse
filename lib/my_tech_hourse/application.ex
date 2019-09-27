defmodule MyTechHourse.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      %{
        id: AirPollutionServer,
        start: {AirPollutionServer, :start_link, []}
      },
      %{
        id: ClimateServer,
        start: {ClimateServer, :start_link, []}
      },
      %{
        id: RefrigeratorServer,
        start: {RefrigeratorServer, :start_link, []}
      },
      %{
        id: GardenServer,
        start: {GardenServer, :start_link, []}
      },
      Plants.Repo,

      # Starts a worker by calling: MyTechHourse.Worker.start_link(arg)
      # {MyTechHourse.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MyTechHourse.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
