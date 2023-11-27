defmodule Systems.NextAction.Presenter do
  use Frameworks.Concept.Presenter

  alias Systems.NextAction

  @impl true
  def view_model(NextAction.OverviewPage, %Core.Accounts.User{} = user, _) do
    %{next_actions: NextAction.Public.list_next_actions(user)}
  end
end
