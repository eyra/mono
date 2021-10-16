defmodule CoreWeb.UI.MarginY do
  @moduledoc """
   Vertical margins between page elements
  """
  use CoreWeb.UI.Component

  prop(id, :string, required: true)

  defp margin(:page_top), do: "pt-6 md:pt-8 lg:pt-14"
  defp margin(:page_footer_top), do: "mt-12 lg:mt-16"
  defp margin(:title2_bottom), do: "mb-6 md:mb-8 lg:mb-10"
  defp margin(:tabbar_footer_top), do: "mt-12 lg:mt-16"
  defp margin(:actionbar), do: "mt-navbar-height"
  defp margin(:button_bar_top), do: "mt-8"

  defp margin(_), do: ""

  def render(assigns) do
    ~H"""
    <div class={{margin(@id)}} />
    """
  end
end
