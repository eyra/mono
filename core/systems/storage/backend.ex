defmodule Systems.Storage.Backend do
  @callback store(
              session :: map(),
              vm :: map(),
              data :: binary()
            ) :: any()
end
