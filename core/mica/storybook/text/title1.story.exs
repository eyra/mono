defmodule Storybook.Frameworks.Pixel.Text.Title1 do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Text.title1/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Page title",
        attributes: %{},
        slots: ["Social media and wellbeing"]
      },
      %Variation{
        id: :primary_centered,
        description: "Primary color, centered",
        attributes: %{color: "text-primary", align: "text-center"},
        slots: ["Thank you for participating"]
      },
      %VariationGroup{
        id: :title_scale,
        description: "Title scale: title0 (largest) to title7 (smallest), each labelled",
        template: title_scale(),
        variations: [
          %Variation{
            id: :title1,
            description: "title1 · page title",
            attributes: %{margin: ""},
            slots: ["Social media and wellbeing"]
          }
        ]
      }
    ]
  end

  defp title_scale do
    """
    <div class="flex flex-col gap-6">
      <div><div class="text-caption font-caption text-grey2 mb-1">title0 · hero heading</div><Frameworks.Pixel.Text.title0>Social media and wellbeing</Frameworks.Pixel.Text.title0></div>
      <div><div class="text-caption font-caption text-grey2 mb-1">title1 · page title</div><.psb-variation-group/></div>
      <div><div class="text-caption font-caption text-grey2 mb-1">title2 · section title</div><Frameworks.Pixel.Text.title2>Social media and wellbeing</Frameworks.Pixel.Text.title2></div>
      <div><div class="text-caption font-caption text-grey2 mb-1">title3 · sub-section title</div><Frameworks.Pixel.Text.title3>Social media and wellbeing</Frameworks.Pixel.Text.title3></div>
      <div><div class="text-caption font-caption text-grey2 mb-1">title4 · block title</div><Frameworks.Pixel.Text.title4>Social media and wellbeing</Frameworks.Pixel.Text.title4></div>
      <div><div class="text-caption font-caption text-grey2 mb-1">title5 · card title (centered by default)</div><Frameworks.Pixel.Text.title5>Social media and wellbeing</Frameworks.Pixel.Text.title5></div>
      <div><div class="text-caption font-caption text-grey2 mb-1">title6 · form section label</div><Frameworks.Pixel.Text.title6>Social media and wellbeing</Frameworks.Pixel.Text.title6></div>
      <div><div class="text-caption font-caption text-grey2 mb-1">title7 · small title</div><Frameworks.Pixel.Text.title7>Social media and wellbeing</Frameworks.Pixel.Text.title7></div>
    </div>
    """
  end
end
