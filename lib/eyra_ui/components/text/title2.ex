defmodule EyraUI.Text.Title2 do
  use Surface.Component

  prop text, :string, required: true

  def render(assigns) do
    ~H"""
    <div class="mb-6 text-title5 font-title5 lg:text-title2 lg:font-title2">
      {{@text}}
    </div>
    """
  end
end
