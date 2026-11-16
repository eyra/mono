defmodule MicaSaas.Frameworks.Pixel.CardLabelTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias Frameworks.Pixel.Card

  @label %{type: :tertiary, text: "Online"}
  @image_info %{url: "", srcset: "", blur_hash: "", width: 10, height: 10}

  defp render(component, assigns) do
    assigns
    |> Map.put(:__changed__, nil)
    |> component.()
    |> rendered_to_string()
    |> Floki.parse_fragment!()
  end

  # The text a screen reader reads from the elements in the card's
  # aria-describedby: their text plus the alt of their images.
  defp description(html) do
    [card] = Floki.find(html, "[role='button']")
    [ids] = Floki.attribute(card, "aria-describedby")

    ids
    |> String.split()
    |> Enum.map_join(" ", fn id ->
      Floki.find(html, "##{id}")
      |> Floki.traverse_and_update(fn
        {"img", attrs, _} -> List.keyfind(attrs, "alt", 0, {"alt", ""}) |> elem(1)
        other -> other
      end)
      |> Floki.text(sep: " ")
    end)
  end

  defp occurrences(text, word), do: length(String.split(text, word)) - 1

  test "the label's arrow is decorative" do
    html = render(&Card.label/1, @label)

    assert Floki.text(html) =~ "Online"
    assert [arrow] = Floki.find(html, "img")
    assert Floki.attribute(arrow, "alt") == [""]
  end

  test "an item card reads its status once" do
    html =
      render(&Systems.Project.CardView.basic/1, %{
        id: 7,
        title: "Data donation",
        label: @label,
        tags: ["Assignment"],
        info: ["0 participants"]
      })

    assert occurrences(description(html), "Online") == 1
  end

  test "an advert card reads its status once" do
    html =
      render(&Systems.Advert.CardView.basic/1, %{
        id: 7,
        title: "Advert",
        label: @label,
        image_info: @image_info,
        target: ""
      })

    assert occurrences(description(html), "Online") == 1
  end
end
