defmodule Core.Systems do
  @moduledoc """
  Mica's own systems (`Core.System`), the start of every `c:Core.SaaS.systems/0`.

  Not in `Core`: about 290 modules `use Core`, and they recompile whenever a
  module that `Core` names changes, or anything that module names. System
  modules name their signal handlers, notifiers and channels, and through them
  most of the app.
  """

  @doc "Routes are spliced in this order. Keep it a literal list."
  def all do
    [
      Systems.Admin.System,
      Systems.Advert.System,
      Systems.Affiliate.System,
      Systems.Alliance.System,
      Systems.Assignment.System,
      Systems.Fund.System,
      Systems.Desktop.System,
      Systems.Document.System,
      Systems.Feldspar.System,
      Systems.Home.System,
      Systems.Lab.System,
      Systems.Manual.System,
      Systems.NextAction.System,
      Systems.Payment.System,
      Systems.Org.System,
      Systems.Pool.System,
      Systems.Project.System,
      Systems.Promotion.System,
      Systems.Storage.System,
      Systems.Support.System,
      Systems.Account.System,
      Systems.Consent.System,
      Systems.Crew.System,
      Systems.Instruction.System,
      Systems.Notify.System,
      Systems.Observatory.System,
      Systems.Workflow.System
    ]
  end
end
