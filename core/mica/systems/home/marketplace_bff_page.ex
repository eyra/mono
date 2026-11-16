defmodule Systems.Home.MarketplaceBFFPage do
  @moduledoc "The BFF's marketplace page: every study open to the user (`Systems.Home.BFFPage.marketplace/1`)."
  @behaviour Systems.BFF.Page

  @impl true
  defdelegate blocks(user), to: Systems.Home.BFFPage, as: :marketplace
end
