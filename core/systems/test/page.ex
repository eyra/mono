defmodule Systems.Test.Page do
  @moduledoc """
  The page for testing the view model observations
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :test_page

  alias Systems.{
    Test
  }

  data(model, :map)

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {
      :ok,
      socket
      |> assign(model: Test.Context.get(id))
      |> observe_view_model()
    }
  end

  defoverridable handle_view_model_updated: 1
  def handle_view_model_updated(socket), do: socket

  def render(assigns) do
    ~F"""
      <div>{@vm.title}</div>
      <div>{@vm.subtitle}</div>
    """
  end
end
