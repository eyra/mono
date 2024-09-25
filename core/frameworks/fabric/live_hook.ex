defmodule Frameworks.Fabric.LiveHook do
  import Phoenix.Component, only: [assign: 2]

  def on_mount(_live_view_module, _params, _session, socket) do
    self = %Fabric.LiveView.RefModel{pid: self()}
    fabric = %Fabric.Model{parent: nil, self: self, children: nil}
    {:cont, socket |> assign(fabric: fabric)}
  end
end
