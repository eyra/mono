defmodule Frameworks.Pixel.NumberIcon do
  use CoreWeb, :pixel

  def center_correction_for_number(1), do: "mr-1px"
  def center_correction_for_number(4), do: "mr-1px"
  def center_correction_for_number(_), do: ""

  def style(true), do: "bg-primary text-white"
  def style(false), do: "bg-grey5 text-grey2"

  attr(:number, :integer, required: true)
  attr(:active, :boolean, default: false)

  def number_icon(assigns) do
    ~H"""
      <div class={"flex-shrink-0 icon w-6 h-6 font-caption text-caption rounded-full flex items-center #{style(@active)}"}
      >
        <span class={"text-center w-full mt-1px #{center_correction_for_number(@number)}"}><%= @number %></span>
      </div>
    """
  end
end
