defmodule Storybook.Frameworks.Pixel.Form.Field do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Form.field/1

  @input ~s(<input class="text-grey1 text-bodymedium font-body pl-3 w-full border-2 border-grey3 rounded h-44px" value="Screen time and wellbeing" />)

  def variations do
    [
      %Variation{
        id: :with_label,
        description: "Label wrapping custom input markup",
        attributes: %{field: :study_title, background: :light, label_text: "Title"},
        slots: [@input]
      },
      %Variation{
        id: :without_label,
        description: "No label",
        attributes: %{field: :study_title, background: :light, label_text: nil},
        slots: [@input]
      },
      %Variation{
        id: :with_errors,
        description: "With errors",
        attributes: %{
          field: :study_title,
          background: :light,
          label_text: "Title",
          errors: [
            {"can't be blank", []},
            {"should be at most %{count} character(s)", [count: 80]}
          ]
        },
        slots: [@input]
      },
      %Variation{
        id: :compact,
        description: "No reserved error space or extra spacing",
        attributes: %{
          field: :study_title,
          background: :light,
          label_text: "Title",
          reserve_error_space: false,
          extra_space: false
        },
        slots: [@input]
      }
    ]
  end
end
