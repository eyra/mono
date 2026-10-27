defmodule Systems.Onyx.System do
  use Core.System

  def routes do
    quote do
      require Systems.Onyx.Routes
      Systems.Onyx.Routes.routes()
    end
  end

  def grants do
    quote do
      [
        {Systems.Onyx.LandingPage, [:admin]}
      ]
    end
  end

  def feature_flags, do: [:onyx]
end
