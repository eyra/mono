defmodule Systems.Storage.Backend do
  @callback store(
              endpoint :: map(),
              panel_info :: map(),
              data :: binary(),
              meta_data :: map()
            ) :: any()
end
