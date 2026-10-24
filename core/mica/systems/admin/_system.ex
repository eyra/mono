defmodule Systems.Admin.System do
  use Core.System

  def routes do
    quote do
      require Systems.Admin.Routes
      Systems.Admin.Routes.routes()
    end
  end

  def grants do
    quote do
      [
        {Systems.Admin.ConfigPage, [:admin]},
        {Systems.Admin.ImportRewardsPage, [:admin]},
        {Systems.Admin.LoginPage, [:visitor, :member]},
        {Systems.Admin.TypographyPage, [:admin]}
      ]
    end
  end
end
