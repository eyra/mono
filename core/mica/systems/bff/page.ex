defmodule Systems.BFF.Page do
  @moduledoc "A page the BFF serves: the blocks it shows the signed-in `user`, in order."

  @callback blocks(user :: Systems.Account.User.t()) :: [struct()]
end
