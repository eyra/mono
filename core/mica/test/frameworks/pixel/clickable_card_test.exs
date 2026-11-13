defmodule Frameworks.Pixel.ClickableCardTest do
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
      <:title :if={@title?}>Project title</:title>
      Body
    </.clickable_card>
    """
  end

  defp render_card(assigns) do
    assigns
    |> Map.merge(%{__changed__: nil})
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

  test "the card is a focusable button" do
    card = render_card(%{title?: true, left_actions: []}) |> open()

    assert attribute(card, "role") == "button"
    assert attribute(card, "tabindex") == "0"
    assert attribute(card, "phx-hook") == "KeyboardClick"
    assert attribute(card, "id") == "card-7-open"
  end

  test "the card is named by its title" do
    html = render_card(%{title?: true, left_actions: []})

    assert html |> open() |> attribute("aria-labelledby") == "card-7-title"
    assert html |> Floki.find("#card-7-title") |> Floki.text() =~ "Project title"
  end

  test "a card without a title has no aria-labelledby" do
    card = render_card(%{title?: false, left_actions: []}) |> open()

    assert attribute(card, "aria-labelledby") == nil
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
