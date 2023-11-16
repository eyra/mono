defmodule Fabric do
  alias Fabric.LiveView
  alias Fabric.LiveComponent

  def prepare_child(
        %Phoenix.LiveView.Socket{assigns: %{fabric: fabric}},
        child_id,
        module,
        params
      ) do
    prepare_child(fabric, child_id, module, params)
  end

  def prepare_child(%Fabric.Model{self: self}, child_id, module, params) do
    child_ref = %LiveComponent.RefModel{id: child_id, module: module}
    child_fabric = %Fabric.Model{parent: self, self: child_ref, children: []}
    params = Map.put(params, :fabric, child_fabric)
    %LiveComponent.Model{ref: child_ref, params: params}
  end

  def get_child(%Phoenix.LiveView.Socket{assigns: %{fabric: fabric}}, child_id) do
    get_child(fabric, child_id)
  end

  def get_child(%Fabric.Model{children: children}, child_id) do
    Enum.find(children, &(&1.ref.id == child_id))
  end

  def new_fabric(%Phoenix.LiveView.Socket{} = socket) do
    fabric = new_fabric()
    Phoenix.Component.assign(socket, :fabric, fabric)
  end

  def new_fabric() do
    %Fabric.Model{parent: nil, children: []}
  end

  def show_child(%Phoenix.LiveView.Socket{} = socket, %LiveComponent.Model{} = child) do
    socket |> add_child(child)
  end

  def replace_child(
        %Phoenix.LiveView.Socket{} = socket,
        %LiveComponent.Model{ref: %{id: id}} = child
      ) do
    socket
    |> remove_child(id)
    |> add_child(child)
  end

  def hide_child(%Phoenix.LiveView.Socket{} = socket, child_id) do
    socket |> remove_child(child_id)
  end

  def show_popup(%Phoenix.LiveView.Socket{} = socket, %LiveComponent.Model{} = child) do
    socket
    |> add_child(child)
    |> send_event(:root, "show_popup", child)
  end

  def hide_popup(%Phoenix.LiveView.Socket{} = socket, child_id) do
    socket
    |> remove_child(child_id)
    |> send_event(:root, "hide_popup")
  end

  def add_child(%Phoenix.LiveView.Socket{assigns: %{fabric: fabric}} = socket, child) do
    fabric = add_child(fabric, child)
    Phoenix.Component.assign(socket, :fabric, fabric)
  end

  def add_child(%Fabric.Model{children: children} = fabric, %LiveComponent.Model{} = child) do
    %Fabric.Model{fabric | children: children ++ [child]}
  end

  def remove_child(%Phoenix.LiveView.Socket{assigns: %{fabric: fabric}} = socket, child_id) do
    fabric = remove_child(fabric, child_id)
    Phoenix.Component.assign(socket, :fabric, fabric)
  end

  def remove_child(%Fabric.Model{children: children} = fabric, child_id) do
    %Fabric.Model{fabric | children: Enum.filter(children, &(&1.ref.id != child_id))}
  end

  def send_event(_, _, _, payload \\ %{})

  def send_event(
        %Phoenix.LiveView.Socket{assigns: %{fabric: fabric}} = socket,
        target,
        name,
        payload
      ) do
    send_event(fabric, target, name, payload)
    socket
  end

  def send_event(%Fabric.Model{}, :root, name, payload) do
    send_event(self(), %{name: name, payload: payload})
  end

  def send_event(%Fabric.Model{parent: nil}, :parent, name, _payload) do
    raise "Sending event '#{name}' to non-existing parent"
  end

  def send_event(%Fabric.Model{parent: parent, self: self}, :parent, name, payload) do
    payload = Map.put(payload, :source, self)
    send_event(parent, %{name: name, payload: payload})
  end

  def send_event(%Fabric.Model{self: self}, :self, name, payload) do
    send_event(self, %{name: name, payload: payload})
  end

  def send_event(%Fabric.Model{} = fabric, child_id, name, payload) do
    if child = get_child(fabric, child_id) do
      send_event(child.ref, %{name: name, payload: payload})
    end
  end

  def send_event(%LiveComponent.RefModel{id: id, module: module}, event) do
    Phoenix.LiveView.send_update(module, %{id: id, fabric_event: event})
  end

  def send_event(%LiveView.RefModel{pid: pid}, event) do
    send_event(pid, event)
  end

  def send_event(pid, event) when is_pid(pid) do
    send(pid, %{fabric_event: event})
  end
end
