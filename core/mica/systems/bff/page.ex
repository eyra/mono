defmodule Systems.BFF.Page do
  @moduledoc """
  A page the BFF serves: the blocks it shows the signed-in `user`, in order. `params`
  are the request's query parameters, such as the values of the page's `filter` and
  `search` blocks (`?year=2025&query=sleep`); a page ignores the ones it doesn't know.
  """

  @callback blocks(user :: Systems.Account.User.t(), params :: %{String.t() => term()}) ::
              [struct()]
end
