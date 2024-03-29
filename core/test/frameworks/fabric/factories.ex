defmodule Fabric.Factories do
  def create_fabric() do
    create_fabric(%Fabric.LiveView.RefModel{pid: self()})
  end

  def create_fabric(%Fabric.LiveView.RefModel{} = self) do
    %Fabric.Model{parent: nil, self: self, children: nil}
  end

  def create_fabric(%Fabric.LiveComponent.RefModel{} = self) do
    %Fabric.Model{parent: nil, self: self, children: nil}
  end

  def create_child(id, module \\ Fabric.LiveComponentMock, params \\ %{}) do
    ref = %Fabric.LiveComponent.RefModel{id: id, name: id, module: module}
    fabric = create_fabric(ref)
    params = Map.put(params, :fabric, fabric)
    %Fabric.LiveComponent.Model{ref: ref, params: params}
  end
end
