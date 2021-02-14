defmodule EyraUI.Button.LinkButton do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component

  prop path, :string, required: true
  prop label, :string, required: true

  def render(assigns) do
    ~H"""
    <a href= {{@path}} class="text-primary text-link font-link hover:text-black underline focus:outline-none" >
       {{@label}}
    </a>
    """
  end
end
