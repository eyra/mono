defmodule Core.NextActions.ViewModel do
  @callback to_view_model(fun(), integer(), map()) :: %{
              title: binary(),
              description: binary(),
              cta: binary(),
              url: binary()
            }
end
