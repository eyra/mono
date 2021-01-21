defmodule EyraUI.Text.Intro do
  use Surface.Component

  prop text, :string, required: true

  def render(assigns) do
    ~H"""
    <div class="text-intro lg:text-introdesktop font-intro lg:mb-9">
      {{@text}}
    </div>
    """
  end
end
