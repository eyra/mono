defmodule Frameworks.Pixel.Spinner do
  use MicaWeb, :html

  alias Frameworks.Pixel.Prism

  attr(:alt, :string, default: "Loading")
  attr(:size, :string, default: "")
  attr(:color, :string, default: nil)

  def static(%{size: size, color: color} = assigns) do
    assigns = assign(assigns, pixels: pixels(size), color_class: color && "text-#{color}")

    ~H"""
    <Prism.spinner size={@pixels} class={@color_class} role="status" aria-label={@alt} />
    """
  end

  defp pixels("w-4 h-4"), do: 16
  defp pixels("w-8 h-8"), do: 32
  defp pixels(_), do: 24
end
