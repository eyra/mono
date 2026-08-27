defmodule CoreWeb.UI do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      import CoreWeb.UI.FunctionComponent
      import CoreWeb.UI.Spacing
      import CoreWeb.UI.Wrap

      alias CoreWeb.UI.Area
      alias CoreWeb.UI.Margin
      alias CoreWeb.UI.Responsive.Breakpoint
      alias CoreWeb.UI.Timestamp
    end
  end
end
