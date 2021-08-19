defmodule CoreWeb.UI.MarginY do
  @moduledoc """
   Vertical margins between page elements
  """
  use CoreWeb.UI.Component

  prop(id, :string, required: true)

  defp margin(:page_top), do: "pt-6 md:pt-8 lg:pt-14"
  defp margin(_), do: ""

  def render(assigns) do
    ~H"""
    <div class={{margin(@id)}} />
    """
  end
end
