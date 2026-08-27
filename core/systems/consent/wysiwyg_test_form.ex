defmodule Systems.Consent.WysiwygTestForm do
  @moduledoc false
  use CoreWeb.LiveForm

  @impl true
  def update(%{x: x}, socket) do
    {
      :ok,
      socket |> assign(x: x) |> update_visible()
    }
  end

  defp update_visible(%{assigns: %{x: nil}} = socket) do
    assign(socket, visible: false)
  end

  defp update_visible(socket) do
    assign(socket, visible: true)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div>
        <div id={:test_form}
          phx-hook="Wysiwyg"
          data-html={@x}
          data-target={@myself}
          data-id="wysiwyg:id"
          data-name="wysiwyg:name"
          data-visible={@visible}
          data-locked={false} />
      </div>
    </div>
    """
  end
end
