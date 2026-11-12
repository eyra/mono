defmodule Next.Systems.Onyx.System do
  use Mica.System

  def routes do
    quote do
      require Next.Systems.Onyx.Routes
      Next.Systems.Onyx.Routes.routes()
    end
  end

  def grants do
    [
      {Next.Systems.Onyx.LandingPage, [:admin]}
    ]
  end

  def feature_flags, do: [:onyx]
end
