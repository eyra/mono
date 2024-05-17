defmodule Systems.Account.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Account

  @impl true
  def view_model(page, model, assigns) do
    builder(page).view_model(model, assigns)
  end

  defp builder(Account.UserProfilePage), do: Account.UserProfilePageBuilder
end
