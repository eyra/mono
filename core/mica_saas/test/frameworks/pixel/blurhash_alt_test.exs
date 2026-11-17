defmodule MicaSaas.Frameworks.Pixel.BlurhashAltTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  @image_info %{url: "/image.png", srcset: "", blur_hash: "LEHV6nWB2yk8", width: 10, height: 10}

  defp render(component, assigns) do
    assigns
    |> Map.put(:__changed__, nil)
    |> component.()
    |> rendered_to_string()
    |> Floki.parse_fragment!()
  end

  defp blurhash(html), do: Floki.find(html, "[phx-hook='Blurhash']")

  test "a card's cover image is decorative" do
    html =
      render(&Systems.Project.CardView.basic/1, %{
        id: 7,
        title: "Data donation",
        label: nil,
        image_info: @image_info,
        info: []
      })

    assert html |> blurhash() |> Floki.attribute("data-alt") == [""]
  end

  test "a manual page's image gets no alt" do
    html =
      render(&Systems.Manual.Html.page/1, %{
        id: "page-1",
        page: %{title: "Step 1", image_info: @image_info, text: nil}
      })

    assert [_] = blurhash(html)
    assert html |> blurhash() |> Floki.attribute("data-alt") == []
  end
end
