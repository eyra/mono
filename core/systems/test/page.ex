defmodule Systems.Test.Page do
  @moduledoc """
  The page for testing the view model observations
  """
  use CoreWeb, :live_view

  on_mount({CoreWeb.Live.Hook.Base, __MODULE__})
  on_mount({CoreWeb.Live.Hook.Model, __MODULE__})
  on_mount({Systems.Observatory.LiveHook, __MODULE__})

  alias Systems.Test

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Test.Public.get(id)
  end

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(
        view_model_updated: 0,
        active_menu_item: nil
      )
    }
  end

  def handle_view_model_updated(%{assigns: %{view_model_updated: view_model_updated}} = socket) do
    socket |> assign(view_model_updated: "#{view_model_updated + 1}")
  end

  # data(model, :map)
  @impl true
  def render(assigns) do
    ~H"""
    <div><%= @vm.title %></div>
    <div><%= @vm.subtitle %></div>
    <div>view_model_updated: <%= @view_model_updated %></div>
    """
  end
end
