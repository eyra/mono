defmodule Systems.Desktop.Switch do
  @moduledoc """
  Signal handler for the Desktop system.

  Desktop is a consumer of NextAction — it renders the next-best-action
  banner on /desktop. Listen for NextAction changes on the affected
  user and refresh the Desktop page so the banner updates live (in
  addition to the to-do count badge that the menus live-hook already
  refreshes).
  """
  use Frameworks.Concept.Switch

  alias Systems.Desktop

  @impl true
  def intercept({:next_action, _}, %{user: user, from_pid: from_pid}) do
    update_routed(Desktop.Page, user, from_pid)
    :ok
  end
end
