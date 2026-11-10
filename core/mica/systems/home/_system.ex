defmodule Systems.Home.System do
  use Mica.System

  def routes do
    quote do
      require Systems.Home.Routes
      Systems.Home.Routes.routes()
    end
  end

  def grants do
    [
      {Systems.Home.Page, [:visitor, :member, :creator]}
    ]
  end

  def signal_handlers, do: [Systems.Home.Switch]

  def bff_pages, do: %{home: Systems.Home.BFFPage}

  def feature_flags, do: [:opp_phase_3]
end
