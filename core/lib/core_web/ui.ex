defmodule CoreWeb.UI do
  defmacro __using__(_) do
    quote do
      import CoreWeb.UI.FunctionComponent
      import CoreWeb.UI.Spacing
      import CoreWeb.UI.Wrap

      alias CoreWeb.UI.Margin
      alias CoreWeb.UI.Area
      alias CoreWeb.UI.Margin
      alias CoreWeb.UI.Responsive.Breakpoint
    end
  end
end
