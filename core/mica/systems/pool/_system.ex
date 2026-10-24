defmodule Systems.Pool.System do
  use Core.System

  def routes do
    quote do
      require Systems.Pool.Routes
      Systems.Pool.Routes.routes()
    end
  end

  def grants do
    quote do
      [
        {Systems.Pool.ContentPage, [:admin]},
        {Systems.Pool.DetailPage, [:creator]},
        {Systems.Pool.LandingPage, [:visitor, :member, :owner]},
        {Systems.Pool.MarketplacePage, [:visitor, :member, :owner]},
        {Systems.Pool.OnboardingPage, [:member]},
        {Systems.Pool.ParticipantPage, [:creator]},
        {Systems.Pool.SubmissionPage, [:creator]}
      ]
    end
  end
end
