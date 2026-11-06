defmodule Next.Storybook.Systems.Announcement.Cards.List do
  use PhoenixStorybook.Story, :component

  def function, do: &Next.Systems.Announcement.Cards.list/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{items: []},
        slots: []
      }
    ]
  end
end
