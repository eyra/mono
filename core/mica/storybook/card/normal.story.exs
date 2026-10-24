defmodule Storybook.Frameworks.Pixel.Card.Normal do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Card.normal/1

  @title ~s|<:title><div class="text-title5 font-title5 lg:text-title4 lg:font-title4 mb-4">Social media and wellbeing</div></:title>|
  @body ~s|<div class="text-bodymedium font-body text-grey2">A 15-minute survey on how your daily social media use relates to sleep and mood.</div>|

  def template do
    """
    <div class="w-96"><.psb-variation/></div>
    """
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Card with title and body",
        slots: [@title, @body]
      },
      %Variation{
        id: :with_image,
        description: "Card with an image slot",
        slots: [
          ~s|<:image><img class="w-full h-40 object-cover rounded-t-lg" src="/images/landing_page/blue-abstract.webp" alt="" /></:image>|,
          @title,
          @body
        ]
      },
      %VariationGroup{
        id: :bg_colors,
        description: "Background colors",
        template: """
        <div class="grid grid-cols-3 gap-4"><.psb-variation-group/></div>
        """,
        variations:
          for bg <- ~w(bg-grey6 bg-grey5 bg-white) do
            %Variation{
              id: String.to_atom(bg),
              description: bg,
              attributes: %{bg_color: bg},
              slots: [@title, @body]
            }
          end
      }
    ]
  end
end
