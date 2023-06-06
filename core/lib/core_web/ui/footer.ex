defmodule CoreWeb.UI.Footer do
  use CoreWeb, :html

  attr(:left, :string, default: "/images/footer-left.svg")
  attr(:right, :string, default: "/images/footer-right.svg")

  def footer(assigns) do
    ~H"""
    <div class="h-footer sm:h-footer-sm lg:h-footer-lg">
      <div class="flex">
        <div class="flex-wrap">
            <img class="h-footer sm:h-footer-sm lg:h-footer-lg" src={@left} alt=""/>
        </div>
        <div class="flex-grow">
        </div>
        <div class="flex-wrap">
            <img class="h-footer sm:h-footer-sm lg:h-footer-lg" src={@right} alt="" />
        </div>
      </div>
    </div>
    """
  end
end
