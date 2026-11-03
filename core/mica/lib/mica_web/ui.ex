defmodule MicaWeb.UI do
  defmacro __using__(_) do
    quote do
      import MicaWeb.UI.FunctionComponent
      import MicaWeb.UI.Spacing
      import MicaWeb.UI.Wrap

      alias MicaWeb.UI.Margin
      alias MicaWeb.UI.Area
      alias MicaWeb.UI.Margin
      alias MicaWeb.UI.Responsive.Breakpoint
      alias MicaWeb.UI.Timestamp
    end
  end
end
