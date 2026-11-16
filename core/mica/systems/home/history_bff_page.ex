defmodule Systems.Home.HistoryBFFPage do
  @moduledoc "The BFF's history page: every study the user took part in (`Systems.Home.BFFPage.history/1`)."
  @behaviour Systems.BFF.Page

  @impl true
  def blocks(user, _params), do: Systems.Home.BFFPage.history(user)
end
