defmodule Fabric.ModalController do
  import Fabric, only: [send_event: 4, get_child: 2, add_child: 2, remove_child: 2]

  require Logger

  def prepared_modal?(context, child_name) do
    if child = get_child(context, child_name) do
      Map.get(child, :prepared_modal_style) != nil
    else
      false
    end
  end

  def prepare_modal(context, nil, _modal_style) do
    Logger.error("Can not prepare modal with unknown child")
    context
  end

  def prepare_modal(context, child_name, modal_style)
      when is_atom(child_name) or is_binary(child_name) do
    if child = get_child(context, child_name) do
      prepared_modal_style = Map.get(child, :prepared_modal_style)

      if prepared_modal_style do
        Logger.debug("already prepared modal style #{prepared_modal_style} for #{child_name}")
        context
      else
        child |> Map.put(child, prepared_modal_style: modal_style)
        prepare_modal(context, child, modal_style)
      end
    else
      Logger.warning("Can not prepare modal with unknown child '#{child_name}'")
      context
    end
  end

  def prepare_modal(
        %Phoenix.LiveView.Socket{assigns: assigns} = socket,
        %Fabric.LiveComponent.Model{} = child,
        modal_style
      ) do
    %Phoenix.LiveView.Socket{socket | assigns: prepare_modal(assigns, child, modal_style)}
  end

  def prepare_modal(
        %{fabric: fabric} = assigns,
        %Fabric.LiveComponent.Model{} = child,
        modal_style
      ) do
    send_event(fabric, :root, "prepare_modal", %{live_component: child, style: modal_style})
    Phoenix.Component.assign(assigns, fabric: add_child(fabric, child))
  end

  def show_modal(context, child_name, modal_style)
      when is_atom(child_name) or is_binary(child_name) do
    if child = get_child(context, child_name) do
      show_modal(context, child, modal_style)
    else
      Logger.warning("Can not show modal with unknown child '#{child_name}'")
      context
    end
  end

  def show_modal(
        %Phoenix.LiveView.Socket{assigns: assigns} = socket,
        %Fabric.LiveComponent.Model{} = child,
        modal_style
      ) do
    %Phoenix.LiveView.Socket{socket | assigns: show_modal(assigns, child, modal_style)}
  end

  def show_modal(%{fabric: fabric} = assigns, %Fabric.LiveComponent.Model{} = child, modal_style) do
    send_event(fabric, :root, "show_modal", %{live_component: child, style: modal_style})
    Phoenix.Component.assign(assigns, fabric: add_child(fabric, child))
  end

  def hide_modal(%Phoenix.LiveView.Socket{assigns: assigns} = socket, child_name) do
    %Phoenix.LiveView.Socket{socket | assigns: hide_modal(assigns, child_name)}
  end

  def hide_modal(%{fabric: fabric} = assigns, child_name) do
    if child = get_child(fabric, child_name) do
      send_event(fabric, :root, "hide_modal", %{live_component: child})
      Phoenix.Component.assign(assigns, fabric: remove_child(fabric, child_name))
    else
      Logger.warning("Can not hide modal with unknown child '#{child_name}'")
      assigns
    end
  end
end
