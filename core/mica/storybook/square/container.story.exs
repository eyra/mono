defmodule Storybook.Frameworks.Pixel.Square.Container do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Square.container/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: [
          ~s(<div class="w-200px h-200px rounded-lg bg-white shadow-2xl p-5">Questionnaire</div><div class="w-200px h-200px rounded-lg bg-white shadow-2xl p-5">Data donation</div>)
        ]
      }
    ]
  end
end
