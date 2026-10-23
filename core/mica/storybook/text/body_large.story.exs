defmodule Storybook.Frameworks.Pixel.Text.BodyLarge do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.body_large/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{},
        slots: ["In this study we explore how daily social media use relates to sleep and mood."]
      },
      %VariationGroup{
        id: :body_scale,
        description: "Body scale: intro (largest) to caption (smallest), each labelled",
        template: body_scale(),
        variations: [
          %Variation{
            id: :body_large,
            description: "body_large",
            slots: [
              "In this study we explore how daily social media use relates to sleep and mood."
            ]
          }
        ]
      }
    ]
  end

  defp body_scale do
    """
    <div class="flex flex-col gap-6">
      <div><div class="text-caption font-caption text-grey2 mb-1">intro · lead paragraph</div><Frameworks.Pixel.Text.intro>In this study we explore how daily social media use relates to sleep and mood.</Frameworks.Pixel.Text.intro></div>
      <div><div class="text-caption font-caption text-grey2 mb-1">body_large</div><.psb-variation-group/></div>
      <div><div class="text-caption font-caption text-grey2 mb-1">body · medium on mobile, large from sm</div><Frameworks.Pixel.Text.body>In this study we explore how daily social media use relates to sleep and mood.</Frameworks.Pixel.Text.body></div>
      <div><div class="text-caption font-caption text-grey2 mb-1">body_medium</div><Frameworks.Pixel.Text.body_medium>In this study we explore how daily social media use relates to sleep and mood.</Frameworks.Pixel.Text.body_medium></div>
      <div><div class="text-caption font-caption text-grey2 mb-1">body_small</div><Frameworks.Pixel.Text.body_small>In this study we explore how daily social media use relates to sleep and mood.</Frameworks.Pixel.Text.body_small></div>
      <div><div class="text-caption font-caption text-grey2 mb-1">label</div><Frameworks.Pixel.Text.label>In this study we explore how daily social media use relates to sleep and mood.</Frameworks.Pixel.Text.label></div>
      <div><div class="text-caption font-caption text-grey2 mb-1">hint</div><Frameworks.Pixel.Text.hint>In this study we explore how daily social media use relates to sleep and mood.</Frameworks.Pixel.Text.hint></div>
      <div><div class="text-caption font-caption text-grey2 mb-1">footnote</div><Frameworks.Pixel.Text.footnote>In this study we explore how daily social media use relates to sleep and mood.</Frameworks.Pixel.Text.footnote></div>
      <div><div class="text-caption font-caption text-grey2 mb-1">caption</div><Frameworks.Pixel.Text.caption>In this study we explore how daily social media use relates to sleep and mood.</Frameworks.Pixel.Text.caption></div>
    </div>
    """
  end
end
