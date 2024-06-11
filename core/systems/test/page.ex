defmodule Systems.Test.Page do
  @moduledoc """
  The page for testing the view model observations
  """
  use Systems.Content.Composer, :live_workspace

  alias Systems.Test

  @impl true
  def get_model(%{"id" => id}, _session, _socket) do
    Test.Public.get(id)
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(active_menu_item: nil)}
  end

  @impl true
  def handle_view_model_updated(socket), do: socket

  @impl true
  def handle_uri(socket), do: socket

  # data(model, :map)
  @impl true
  def render(assigns) do
    ~H"""
    <div><%= @vm.title %></div>
    <div><%= @vm.subtitle %></div>
    """
  end
end
