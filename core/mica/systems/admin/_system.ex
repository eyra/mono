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

  def signal_handlers, do: [Systems.Admin.Switch]

  def admin_panels do
    [
      Systems.Admin.SystemPanel,
      Systems.Admin.AccountPanel,
      Systems.Admin.OrgPanel,
      Systems.Admin.ActionsPanel,
      Systems.Admin.ClientActivityPanel
    ]
  end

  def feature_flags, do: [:debug_expire_force]
end
