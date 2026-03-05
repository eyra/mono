defmodule Systems.Bookkeeping.AccountStrategy do
  @moduledoc false
  alias Systems.Bookkeeping.AccountModel

  @callback resolve(id :: atom(), description :: binary()) :: AccountModel.t()
end
