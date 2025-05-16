defmodule Frameworks.Fabric.LiveHook do
  use Frameworks.Concept.LiveHook
  import Phoenix.Component, only: [assign: 2]

  @impl true
  def mount(_live_view_module, _params, _session, socket) do
    self = %Fabric.LiveView.RefModel{pid: self()}
    fabric = %Fabric.Model{parent: nil, self: self, children: nil}
    {:cont, socket |> assign(fabric: fabric)}
  end
end
