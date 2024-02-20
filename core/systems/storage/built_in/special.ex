defmodule Systems.Storage.BuiltIn.Special do
  @callback store(
              folder :: binary(),
              identifier :: list(binary()),
              data :: binary()
            ) :: any()
end
