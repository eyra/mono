defmodule Frameworks.Fabric.LiveViewMountPlug do
  defmacro __using__(_) do
    quote do
      @before_compile Frameworks.Fabric.LiveViewMountPlug
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defoverridable mount: 3

      @doc """
        Automatically assigns Fabric to the socket on mount
      """
      def mount(params, session, socket) do
        self = %Fabric.LiveView.RefModel{pid: self()}
        fabric = %Fabric.Model{parent: nil, self: self, children: nil}
        super(params, session, socket |> Phoenix.Component.assign(:fabric, fabric))
      end
    end
  end
end
