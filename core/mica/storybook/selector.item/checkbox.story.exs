defmodule Storybook.Frameworks.Pixel.Selector.Item.Checkbox do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Selector.Item.checkbox/1

  def variations do
    [
      %Variation{
        id: :unselected,
        description: "Unselected",
        attributes: %{item: %{id: :weekly, value: "Weekly", active: false}}
      },
      %Variation{
        id: :selected,
        description: "Selected",
        attributes: %{item: %{id: :weekly, value: "Weekly", active: true}}
      },
      %Variation{
        id: :single_select,
        description: "Single-select font (multiselect? false)",
        attributes: %{
          item: %{id: :consent, value: "I agree to participate", active: true},
          multiselect?: false
        }
      },
      %Variation{
        id: :tertiary_accent,
        description: "Tertiary accent on dark background",
        attributes: %{item: %{id: :weekly, value: "Weekly", active: true, accent: :tertiary}},
        template: ~s(<div class="bg-grey1 p-4"><.psb-variation/></div>)
      },
      %Variation{
        id: :raw_html,
        description: "Raw HTML label",
        attributes: %{
          item: %{id: :terms, value: "I accept the <b>terms</b>", active: false},
          raw?: true
        }
      }
    ]
  end
end
