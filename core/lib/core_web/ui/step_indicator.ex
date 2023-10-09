defmodule CoreWeb.UI.StepIndicator do
  @moduledoc """
    Circle with a number
  """
  use CoreWeb, :html

  defp center_correction_for_number(1), do: "mr-px"
  defp center_correction_for_number(4), do: "mr-px"
  defp center_correction_for_number(_), do: ""

  attr(:text, :string, required: true)
  attr(:bg_color, :string, default: "bg-primary")
  attr(:text_color, :string, default: "text-white")

  def step_indicator(assigns) do
    ~H"""
    <div class={"w-6 h-6 font-caption text-caption rounded-full flex items-center #{@bg_color} #{@text_color}"}>
      <span class={"text-center w-full mt-px #{center_correction_for_number(@text)}"}><%= @text %></span>
    </div>
    """
  end
end
