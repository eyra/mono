defmodule Frameworks.Fabric.LiveHook do
  @moduledoc false
  use Frameworks.Concept.LiveHook

  import Phoenix.Component, only: [assign: 2]

  @impl true
  def mount(_live_view_module, _params, _session, socket) do
    self = %Fabric.LiveView.RefModel{pid: self()}
    fabric = %Fabric.Model{parent: nil, self: self, children: nil}
    {:cont, assign(socket, fabric: fabric)}
  end
end
