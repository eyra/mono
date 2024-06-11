defmodule CoreWeb.Language do
  @moduledoc """
  """
  use CoreWeb, :html

  attr(:language, :any, required: true)
  attr(:label, :string, required: true)

  def language(assigns) do
    ~H"""
    <div class="text-grey1">
      <div class="flex flex-row items-center gap-3 h-full">
        <div class="text-title6 font-title6 mr-1">
          <%= @label %>:
        </div>
        <div>
          <img src={~p"/images/icons/#{"#{@language}.svg"}"} alt={"#{@language}"}>
        </div>
      </div>
    </div>
    """
  end
end
