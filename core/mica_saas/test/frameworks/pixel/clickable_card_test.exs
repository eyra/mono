defmodule MicaSaas.Frameworks.Pixel.ClickableCardTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest
  import Frameworks.Pixel.ClickableCard

  @action %{
    action: %{type: :send, event: "rename", item: 7},
    face: %{type: :label, label: "Rename"}
  }

  defp card(assigns) do
    ~H"""
    <.clickable_card id={7} left_actions={@left_actions}>
      <:top :if={@top?}>Concept</:top>
      <:title :if={@title?}>Project title</:title>
      Body
    </.clickable_card>
    """
  end

  defp render_card(assigns) do
    %{__changed__: nil, top?: false}
    |> Map.merge(assigns)
    |> card()
    |> rendered_to_string()
    |> Floki.parse_fragment!()
  end

  defp open(html), do: html |> Floki.find("[data-testid='card_7']") |> hd()

  defp attribute(element, name) do
    case Floki.attribute(element, name) do
      [value] -> value
      [] -> nil
    end
  end

  test "the show and hide toggles are buttons outside the card's button" do
    html = render_card(%{title?: true, left_actions: [@action]})

    for id <- ["card-7-show-more", "card-7-hide-more"] do
      assert [toggle] = Floki.find(html, "button##{id}")
      assert attribute(toggle, "type") == "button"
      assert [_] = Floki.find(toggle, "img[alt]:not([alt=''])")
      assert html |> open() |> Floki.find("##{id}") == []
    end
  end
end
