defmodule Systems.Home.MarketplaceBFFPage do
  @moduledoc """
  The BFF's marketplace page: every study open to the user, with a year filter and a
  search (`Systems.Home.BFFPage.marketplace/2`).
  """
  @behaviour Systems.BFF.Page

  @impl true
  def view_model(user, params), do: {Systems.Home.BFFPage.marketplace(user, params), []}
end
