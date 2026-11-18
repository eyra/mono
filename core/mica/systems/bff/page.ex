defmodule Systems.BFF.Page do
  @moduledoc """
  A page the BFF serves: the blocks it shows the signed-in `user`, in order, for
  `params`, the page's params from the spec read from the query and typed
  (`Systems.BFF.Blocks.page_params/2`): `?year=2025` is `%{year: 2025}`. A param that
  is missing, empty or doesn't parse is not in `params`.
  """

  @callback blocks(user :: Systems.Account.User.t(), params :: %{atom() => term()}) ::
              [struct()]
end
