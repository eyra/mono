defmodule Frameworks.Pixel.Annotation do
  @moduledoc """
  A pixel component for displaying an annotation.
  Note: this has no relation to the annotation system.
  """
  use CoreWeb, :pixel

  alias Frameworks.Pixel.Panel

  attr(:annotation, :string, required: true)

  def panel(assigns) do
    ~H"""
      <Panel.flat bg_color="bg-grey1">
        <.view annotation={@annotation} />
      </Panel.flat>
    """
  end

  attr(:annotation, :string, required: true)

  def view(assigns) do
    ~H"""
      <div class="wysiwyg wysiwyg-dark">
        <%= raw @annotation %>
      </div>
    """
  end
end
