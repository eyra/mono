defmodule Storybook.Frameworks.Pixel.Form.CurrencyInput do
  use PhoenixStorybook.Story, :component

  def function, do: &Frameworks.Pixel.Form.currency_input/1

  def variations do
    [
      %Variation{
        id: :empty,
        description: "Empty field",
        attributes: %{form: form(%{}), field: :amount, label_text: nil}
      },
      %Variation{
        id: :prefilled,
        description: "Prefilled value",
        attributes: %{form: form(%{"amount" => "12.50"}), field: :amount, label_text: nil}
      },
      %Variation{
        id: :with_label,
        description: "With label",
        attributes: %{form: form(%{}), field: :amount, label_text: "Reward"}
      },
      %Variation{
        id: :disabled,
        description: "Disabled",
        attributes: %{
          form: form(%{"amount" => "12.50"}),
          field: :amount,
          label_text: "Reward",
          disabled: true
        }
      },
      %Variation{
        id: :with_error,
        description: "With a validation error",
        attributes: %{
          form: form(%{"amount" => ""}, errors: [amount: {"must be a positive amount", []}]),
          field: :amount,
          label_text: "Reward"
        }
      },
      %Variation{
        id: :single_currency,
        description: "Single currency (no selector)",
        attributes: %{
          form: form(%{"amount" => "5.00"}),
          field: :amount,
          label_text: "Reward",
          currencies: [:EUR]
        }
      },
      %Variation{
        id: :usd,
        description: "USD active",
        attributes: %{
          form: form(%{"amount" => "20.00"}),
          field: :amount,
          label_text: "Reward",
          active_currency: :USD
        }
      }
    ]
  end

  defp form(params, opts \\ []), do: Phoenix.Component.to_form(params, [as: :study] ++ opts)
end
