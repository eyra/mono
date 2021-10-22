defmodule EyraUI.Card.Label do
  @moduledoc """
   Flag-like label used on a card to highlight specific state
  """
  use Surface.Component

  alias EyraUI.Text.Title5

  prop(conn, :any, required: true)
  prop(path_provider, :any, required: true)
  prop(text, :string, required: true)
  prop(type, :atom, default: :primary)

  def bg_color(:delete), do: "bg-delete"
  def bg_color(:warning), do: "bg-warning"
  def bg_color(:success), do: "bg-success"
  def bg_color(:primary), do: "bg-primary"
  def bg_color(:secondary), do: "bg-secondary"
  def bg_color(:tertiary), do: "bg-tertiary"
  def bg_color(:disabled), do: "bg-grey3"
  def bg_color(type), do: "bg-#{type}"

  def text_color(:tertiary), do: "text-grey1"
  def text_color(_), do: "text-white"

  def render(assigns) do
    ~H"""
    <div class="flex" >
      <div class="h-14 pl-4 pr-2 {{bg_color(@type)}}">
        <div class="flex flex-row justify-center h-full items-center">
          <Title5 color={{ text_color(@type) }}>{{@text}}</Title5>
        </div>
      </div>
      <img src={{ @path_provider.static_path(@conn, "/images/label-arrow-#{@type}.svg")}} alt={{@text}}/>
    </div>
    """
  end
end
