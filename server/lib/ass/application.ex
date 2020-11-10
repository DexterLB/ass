defmodule Ass.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Supervisor.Spec

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Ass.Worker.start_link(arg)
      # {Ass.Worker, arg},

      supervisor(Ass.Repo, []),

      {
        Plug.Adapters.Cowboy,
        scheme: :http,
        plug: Ass.Router,
        options: [
          port: Application.fetch_env!(:ass, :http_port),
        ]
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ass.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
