defmodule CoreWeb.Live.Feature.Tabbed do
  defmacro __using__(_opts \\ nil) do
    quote do
      alias CoreWeb.UI.Responsive.Breakpoint

      def tabbar_size({:unknown, _}), do: :unknown
      def tabbar_size(bp), do: Breakpoint.value(bp, :narrow, sm: %{30 => :wide})

      defoverridable tabbar_size: 1

      def update_tabbar_size(%{assigns: %{breakpoint: breakpoint}} = socket) do
        tabbar_size = tabbar_size(breakpoint)
        socket |> assign(tabbar_size: tabbar_size)
      end
    end
  end
end
