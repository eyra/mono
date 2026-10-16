defmodule Systems.Bookkeeping.AccountStrategy do
  alias Systems.Bookkeeping.AccountModel

  @callback resolve(id :: atom(), description :: binary()) :: AccountModel.t()
end
