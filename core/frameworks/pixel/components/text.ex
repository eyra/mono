defmodule Frameworks.Pixel.Text do
  use CoreWeb, :html

  attr(:color, :string, default: "text-grey1")
  attr(:align, :string, default: "text-left")
  slot(:inner_block, required: true)

  def body_small(assigns) do
    ~H"""
    <div class={"flex-wrap text-bodysmall font-body #{@color} #{@align}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:color, :string, default: "text-grey1")
  attr(:align, :string, default: "text-left")
  slot(:inner_block, required: true)

  def body_medium(assigns) do
    ~H"""
    <div class={"flex-wrap text-bodymedium font-body #{@color} #{@align}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:color, :string, default: "text-grey1")
  attr(:align, :string, default: "text-left")
  slot(:inner_block, required: true)

  def body_large(assigns) do
    ~H"""
    <div class={"flex-wrap text-bodylarge font-body #{@color} #{@align}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:color, :string, default: "text-grey1")
  attr(:align, :string, default: "text-left")
  slot(:inner_block, required: true)

  def body(assigns) do
    ~H"""
    <div class={"flex-wrap text-bodymedium sm:text-bodylarge font-body #{@color} #{@align}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:color, :string, default: "text-grey1")
  attr(:image, :string, required: true)
  slot(:inner_block, required: true)

  def bullet(assigns) do
    ~H"""
    <div class="flex flex-row items-center">
      <div class={"flex-wrap h-3 w-3 mr-3 flex-shrink-0 #{@color}"}>
        <img src={@image} alt="">
      </div>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:color, :string, default: "text-grey3")
  attr(:text_alignment, :string, default: "text-center")
  attr(:padding, :string, default: "pl-4 pr-4")
  attr(:margin, :string, default: "mb-6")
  slot(:inner_block, required: true)

  def caption(assigns) do
    ~H"""
    <div class={"text-caption font-caption #{@padding} #{@text_alignment} #{@color}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:id, :any, required: true)
  attr(:color, :string, default: "text-grey1")
  slot(:inner_block, required: true)

  def form_field_label(assigns) do
    ~H"""
    <div id={@id} class={"mt-0.5 text-title6 font-title6 leading-snug  #{@color}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:color, :string, default: "text-grey2")
  slot(:inner_block, required: true)

  def footnote(assigns) do
    ~H"""
    <div class={"text-footnote font-footnote #{@color}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:color, :string, default: "text-grey1")
  attr(:margin, :string, default: "lg:mb-9")
  slot(:inner_block, required: true)

  def intro(assigns) do
    ~H"""
    <div class={"text-intro lg:text-introdesktop font-intro #{@margin} #{@color}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:color, :string, default: "text-grey1")
  slot(:inner_block, required: true)

  def label(assigns) do
    ~H"""
    <div class={"text-label font-label leading-5 #{@color}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:color, :string, default: "text-grey2")
  slot(:inner_block, required: true)

  def sub_head(assigns) do
    ~H"""
    <div class={"text-intro lg:text-subhead font-subhead tracking-wider #{@color}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:color, :string, default: "text-grey2")
  slot(:inner_block, required: true)

  def hint(assigns) do
    ~H"""
    <div class={"text-hint font-hint #{@color}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:color, :string, default: "text-grey1")
  slot(:inner_block, required: true)

  def title0(assigns) do
    ~H"""
    <div class={"text-title4 font-title4 sm:text-title2 sm:font-title2 lg:text-title0 lg:font-title0 #{@color}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:color, :string, default: "text-grey1")
  slot(:inner_block, required: true)

  def table_head(assigns) do
    ~H"""
    <div class={"text-tablehead font-tablehead"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:color, :string, default: "text-grey1")
  slot(:inner_block, required: true)

  def table_row(assigns) do
    ~H"""
    <div class={"text-tablerow font-tablerow"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:color, :string, default: "text-grey1")
  attr(:margin, :string, default: "mb-7 lg:mb-9")
  slot(:inner_block, required: true)

  def title1(assigns) do
    ~H"""
    <div class={"text-title3 font-title3 sm:text-title2 lg:text-title1 lg:font-title1 #{@margin} #{@color}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:color, :string, default: "text-grey1")
  attr(:margin, :string, default: "mb-5 md:mb-6 lg:mb-8")
  slot(:inner_block, required: true)

  def title2(assigns) do
    ~H"""
    <div class={"text-title4 font-title4 sm:text-title3 sm:font-title3 lg:text-title2 lg:font-title2 #{@margin} #{@color}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:color, :string, default: "text-grey1")
  attr(:margin, :string, default: "mb-5")
  slot(:inner_block, required: true)

  def title3(assigns) do
    ~H"""
    <div class={"text-title5 font-title5 sm:text-title4 sm:font-title4 lg:text-title3 lg:font-title3 #{@margin} #{@color}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:color, :string, default: "text-grey1")
  slot(:inner_block, required: true)

  def title4(assigns) do
    ~H"""
    <div class={"text-title6 font-title6 sm:text-title5 sm:font-title5 lg:text-title4 lg:font-title4 #{@color}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:color, :string, default: "text-grey1")
  attr(:align, :string, default: "text-center")
  slot(:inner_block, required: true)

  def title5(assigns) do
    ~H"""
    <div class={"text-title7 font-title7 sm:text-title5 sm:font-title5 #{@align} #{@color}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:margin, :string, default: "mb-2")
  attr(:color, :string, default: "text-grey1")
  slot(:inner_block, required: true)

  def title6(assigns) do
    ~H"""
    <div class={"text-title6 font-title6 #{@margin} #{@color}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
