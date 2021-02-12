defmodule EyraUI.Text.Section do
  @moduledoc """
  Container that makes the content appear centralized by adding margin to the right to adjust for the left sidebar.
  """
  use Surface.Component
  alias EyraUI.Text.Title3

  @doc "The content"
  slot default, required: true
  prop title, :string, required: true

  def render(assigns) do
    ~H"""
    <div class="mt-12 lg:mt-16"/>
    <Title3>{{@title}}</Title3>
    <slot />
    """
  end
end
