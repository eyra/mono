defmodule Storybook.Frameworks.Pixel.Empty.Empty do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Empty.empty/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          title: "No projects yet",
          body: "Projects you create or are invited to will appear here.",
          illustration: "cards"
        }
      },
      %Variation{
        id: :with_button,
        attributes: %{
          title: "No members yet",
          body: "Invite colleagues to collaborate on this pool.",
          illustration: "members",
          button: %{
            action: %{type: :send, event: "invite"},
            face: %{type: :primary, label: "Invite member"}
          }
        }
      }
    ]
  end
end
