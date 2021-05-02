defmodule EyraUI.Card.Label do
  @moduledoc """
   Flag-like label used on a card to highlight specific state
  """
  use Surface.Component

  alias EyraUI.Text.Title5

  prop(conn, :any, required: true)
  prop(path_provider, :any, required: true)
  prop(text, :string, required: true)
  prop(type, :string, default: "primary")

  def render(assigns) do
    ~H"""
    <div class="flex" >
      <div class="h-14 pl-4 pr-2 bg-{{@type}}">
        <div class="flex flex-row justify-center h-full items-center">
          <Title5>{{@text}}</Title5>
        </div>
      </div>
      <img src={{ @path_provider.static_path(@conn, "/images/label-arrow-#{@type}.svg")}} />
    </div>
    """
  end
end
