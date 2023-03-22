defmodule Frameworks.Pixel.Square do
  use Surface.Component

  alias Frameworks.Pixel.Text.Title5
  alias Frameworks.Pixel.Button.DynamicAction
  alias Frameworks.Pixel.Icon

  prop(icon, :any, default: nil)
  prop(title, :string, required: true)
  prop(subtitle, :any)
  prop(state, :any, default: :solid)
  prop(action, :any, required: true)

  defp style(:solid), do: "bg-white shadow-2xl"
  defp style(:transparent), do: "bg-square-border-striped bg-opacity-0"
  defp style(:active), do: "border-2 border-primary bg-opacity-0"
  defp style({:active, :success}), do: "border-2 border-success bg-opacity-0"
  defp style({:active, :warning}), do: "border-2 border-warning bg-opacity-0"
  defp style({:active, :error}), do: "border-2 border-error bg-opacity-0"

  defp subtitle_style(:active), do: "text-primary"
  defp subtitle_style({:active, :success}), do: "text-success"
  defp subtitle_style({:active, :warning}), do: "text-warning"
  defp subtitle_style({:active, :error}), do: "text-error"
  defp subtitle_style(_), do: "text-grey2"

  defp icon_type({type, _}), do: type
  defp icon_src({_, src}), do: src

  def render(assigns) do
    ~F"""
    <DynamicAction vm={@action}>
      <div class={"flex flex-col gap-4 w-200px h-200px px-4 py-5 items-center justify-center rounded-lg cursor-pointer #{style(@state)}"}>
        <Icon :if={@icon} type={icon_type(@icon)} src={icon_src(@icon)} />
        <Title5>{@title}</Title5>
        <Title5 :if={@subtitle} color={subtitle_style(@state)}>{@subtitle}</Title5>
      </div>
    </DynamicAction>
    """
  end
end
