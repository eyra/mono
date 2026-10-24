defmodule Storybook.Systems.Zircon.Screening.HTML.CriterionCell do
  use PhoenixStorybook.Story, :component

  import Phoenix.Component, only: [sigil_H: 2]

  def function, do: &Systems.Zircon.Screening.HTML.criterion_cell/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Screening criterion with its nested form element",
        attributes: %{
          id: "criterion_form_0",
          title: "Population",
          socket: nil,
          live_nest_element: %{
            id: "criterion_form_0",
            type: :component,
            implementation: &__MODULE__.criterion_form/1,
            options: [statement: "Adolescents aged 12 to 18 years"]
          }
        }
      }
    ]
  end

  # Stand-in for the Annotation.Form live component that criteria_view nests here
  def criterion_form(assigns) do
    ~H"""
    <div class="text-bodymedium font-body text-grey1">{@statement}</div>
    """
  end
end
