defmodule Systems.NextAction.ViewModel do
  @moduledoc false
  @callback to_view_model(integer(), map()) :: %{
              title: binary(),
              description: binary(),
              cta_label: binary(),
              cta_action: map()
            }
end
