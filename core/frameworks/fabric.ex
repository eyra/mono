defmodule Fabric do
  @type assigns :: map()
  @type composition_id :: atom()
  @type composition :: child() | element()
  @type child :: %{module: module(), params: map()}
  @type element :: map() | binary() | number()

  @callback compose(id :: composition_id(), a :: assigns()) :: composition() | nil

  defmacro __using__(_opts) do
    quote do
      @behaviour Fabric

      import Fabric
      import Fabric.Html

      require Logger

      def compose_element(%Phoenix.LiveView.Socket{assigns: assigns} = socket, element_id)
          when is_atom(element_id) do
        %Phoenix.LiveView.Socket{socket | assigns: compose_element(assigns, element_id)}
      end

      def compose_element(%{} = assigns, element_id) when is_atom(element_id) do
        element = compose(element_id, assigns)
        Phoenix.Component.assign(assigns, element_id, element)
      end

      def update_child(context, child_name) when is_atom(child_name) do
        if exists?(context, child_name) do
          compose_child(context, child_name)
        else
          context
        end
      end

      def compose_child(%Phoenix.LiveView.Socket{assigns: assigns} = socket, child_name)
          when is_atom(child_name) do
        %Phoenix.LiveView.Socket{socket | assigns: compose_child(assigns, child_name)}
      end

      def compose_child(%{fabric: fabric} = assigns, child_name) when is_atom(child_name) do
        fabric =
          if child = prepare_child(fabric, child_name, compose(child_name, assigns)) do
            add_child(fabric, child)
          else
            remove_child(fabric, child_name)
          end

        Phoenix.Component.assign(assigns, fabric: fabric)
      end

      def compose(_id, _assigns) do
        Logger.error("compose/2 not implemented")
        nil
      end

      defoverridable compose: 2
    end
  end

  # Child id

  def child_id(%Fabric.Model{self: self}, child_name), do: child_id(self, child_name)

  def child_id(%{pid: pid}, child_name) do
    pid_string =
      pid
      |> :erlang.pid_to_list()
      |> to_string()
      |> then(&("PID" <> &1))

    child_id(pid_string, child_name)
  end

  def child_id(%{id: id}, child_name), do: child_id(id, child_name)
  def child_id(context, child_name), do: "#{child_name}->#{context}"
  # Prepare

  def prepare_child(context, child_name, %{module: module, params: params}) do
    prepare_child(context, child_name, module, params)
  end

  def prepare_child(_context, _child_id, _), do: nil

  def prepare_child(
        %Phoenix.LiveView.Socket{assigns: assigns},
        child_name,
        module,
        params
      ) do
    prepare_child(assigns, child_name, module, params)
  end

  def prepare_child(%{fabric: fabric}, child_name, module, params) do
    prepare_child(fabric, child_name, module, params)
  end

  def prepare_child(%Fabric.Model{self: self}, child_name, module, params) do
    child_id = child_id(self, child_name)
    child_ref = %Fabric.LiveComponent.RefModel{id: child_id, name: child_name, module: module}
    child_fabric = %Fabric.Model{parent: self, self: child_ref, children: nil}
    params = Map.put(params, :fabric, child_fabric)
    %Fabric.LiveComponent.Model{ref: child_ref, params: params}
  end

  # Install

  def install_children(%Phoenix.LiveView.Socket{assigns: %{fabric: fabric}} = socket, children)
      when is_list(children) do
    Phoenix.Component.assign(socket, fabric: install_children(fabric, children))
  end

  def install_children(%{fabric: fabric} = assigns, children) when is_list(children) do
    Phoenix.Component.assign(assigns, fabric: install_children(fabric, children))
  end

  def install_children(%Fabric.Model{} = fabric, children) when is_list(children) do
    %Fabric.Model{fabric | children: children}
  end

  # CRUD

  def get_child(%Phoenix.LiveView.Socket{assigns: %{fabric: fabric}}, child_name) do
    get_child(fabric, child_name)
  end

  def get_child(%{fabric: fabric}, child_name) do
    get_child(fabric, child_name)
  end

  def get_child(%Fabric.Model{children: children}, child_name) do
    Enum.find(List.wrap(children), &(&1.ref.name == child_name))
  end

  def exists?(context, child_name) do
    get_child(context, child_name) != nil
  end

  def new_fabric(%Phoenix.LiveView.Socket{} = socket) do
    fabric = new_fabric()
    Phoenix.Component.assign(socket, :fabric, fabric)
  end

  def new_fabric() do
    %Fabric.Model{parent: nil, children: nil}
  end

  def show_child(
        %Phoenix.LiveView.Socket{assigns: assigns} = socket,
        %Fabric.LiveComponent.Model{} = child
      ) do
    %Phoenix.LiveView.Socket{socket | assigns: show_child(assigns, child)}
  end

  def show_child(%{fabric: fabric} = assigns, %Fabric.LiveComponent.Model{} = child) do
    Phoenix.Component.assign(assigns, fabric: add_child(fabric, child))
  end

  def replace_child(
        %Phoenix.LiveView.Socket{assigns: assigns} = socket,
        %Fabric.LiveComponent.Model{} = child
      ) do
    %Phoenix.LiveView.Socket{socket | assigns: replace_child(assigns, child)}
  end

  def replace_child(
        %{fabric: fabric} = assigns,
        %Fabric.LiveComponent.Model{ref: %{id: id}} = child
      ) do
    Phoenix.Component.assign(assigns,
      fabric:
        fabric
        |> remove_child(id)
        |> add_child(child)
    )
  end

  def hide_child(%Phoenix.LiveView.Socket{assigns: assigns} = socket, child_name) do
    %Phoenix.LiveView.Socket{socket | assigns: hide_child(assigns, child_name)}
  end

  def hide_child(%{fabric: fabric} = assigns, child_name) do
    Phoenix.Component.assign(assigns, fabric: remove_child(fabric, child_name))
  end

  def show_popup(context, child_name) when is_atom(child_name) do
    child = get_child(context, child_name)
    show_popup(context, child)
  end

  def show_popup(
        %Phoenix.LiveView.Socket{assigns: assigns} = socket,
        %Fabric.LiveComponent.Model{} = child
      ) do
    %Phoenix.LiveView.Socket{socket | assigns: show_popup(assigns, child)}
  end

  def show_popup(%{fabric: fabric} = assigns, %Fabric.LiveComponent.Model{} = child) do
    send_event(fabric, :root, "show_popup", child)
    Phoenix.Component.assign(assigns, fabric: add_child(fabric, child))
  end

  def hide_popup(%Phoenix.LiveView.Socket{assigns: assigns} = socket, child_name) do
    %Phoenix.LiveView.Socket{socket | assigns: hide_popup(assigns, child_name)}
  end

  def hide_popup(%{fabric: fabric} = assigns, child_name) do
    send_event(fabric, :root, "hide_popup")
    Phoenix.Component.assign(assigns, fabric: remove_child(fabric, child_name))
  end

  def add_child(%Fabric.Model{children: nil} = fabric, %Fabric.LiveComponent.Model{} = child) do
    %Fabric.Model{fabric | children: [child]}
  end

  def add_child(%Fabric.Model{children: children} = fabric, %Fabric.LiveComponent.Model{} = child) do
    children =
      if index = Enum.find_index(children, &(&1.ref.id == child.ref.id)) do
        List.replace_at(children, index, child)
      else
        List.wrap(child) ++ List.wrap(children)
      end

    %Fabric.Model{fabric | children: children}
  end

  def remove_child(%Fabric.Model{} = fabric, nil), do: fabric

  def remove_child(%Fabric.Model{children: children} = fabric, child_name) do
    %Fabric.Model{
      fabric
      | children: Enum.filter(List.wrap(children), &(&1.ref.name != child_name))
    }
  end

  # Flow
  def show_next(%Phoenix.LiveView.Socket{assigns: %{fabric: fabric}} = socket) do
    Phoenix.Component.assign(socket, fabric: show_next(fabric))
  end

  def show_next(%Fabric.Model{children: children} = fabric) do
    %Fabric.Model{fabric | children: List.wrap(children) |> List.delete_at(0)}
  end

  def get_current_child(%Fabric.Model{children: children}) do
    List.wrap(children) |> List.first()
  end

  # Events

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

  def send_event(%Fabric.Model{children: [%{ref: ref} | _]}, :flow, name, payload) do
    send_event(ref, %{name: name, payload: payload})
  end

  def send_event(%Fabric.Model{}, :flow, name, _payload) do
    raise "Sending event '#{name}' to empty flow"
  end

  def send_event(%Fabric.Model{} = fabric, child_name, name, payload) do
    if child = get_child(fabric, child_name) do
      send_event(child.ref, %{name: name, payload: payload})
    end
  end

  def send_event(%Fabric.LiveComponent.RefModel{id: id, module: module}, event) do
    Phoenix.LiveView.send_update(module, %{id: id, fabric_event: event})
  end

  def send_event(%Fabric.LiveView.RefModel{pid: pid}, event) do
    send_event(pid, event)
  end

  def send_event(pid, event) when is_pid(pid) do
    send(pid, %{fabric_event: event})
  end
end
