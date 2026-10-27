defmodule Systems.Fund.System do
  use Core.System

  def routes do
    quote do
      require Systems.Fund.Routes
      Systems.Fund.Routes.routes()
    end
  end

  def grants do
    quote do
      [
        {Systems.Fund.FundingPage, [:admin, :creator]}
      ]
    end
  end
end
