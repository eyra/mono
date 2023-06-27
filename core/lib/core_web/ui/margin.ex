defmodule CoreWeb.UI.Margin do
  use Phoenix.Component

  attr(:id, :atom, required: true)

  def y(%{id: id} = assigns) do
    assigns =
      assign(
        assigns,
        :margin,
        case id do
          :page_top -> "pt-6 md:pt-8 lg:pt-14"
          :page_footer_top -> "mt-12 lg:mt-16"
          :title2_bottom -> "mb-6 md:mb-8 lg:mb-10"
          :tabbar_footer_top -> "mt-12 lg:mt-16"
          :actionbar -> "mt-navbar-height"
          :button_bar_top -> "mt-8"
          _ -> ""
        end
      )

    ~H"""
    <div class={@margin} />
    """
  end
end
