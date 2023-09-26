defmodule Systems.Test.Page do
  @moduledoc """
  The page for testing the view model observations
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :test_page
  use Systems.Observatory.Public

  alias Systems.{
    Test
  }

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {
      :ok,
      socket
      |> assign(model: Test.Public.get(id))
      |> observe_view_model()
    }
  end

  defoverridable handle_view_model_updated: 1
  def handle_view_model_updated(socket), do: socket

  # data(model, :map)
  @impl true
  def render(assigns) do
    ~H"""
    <div><%= @vm.title %></div>
    <div><%= @vm.subtitle %></div>
    """
  end
end
