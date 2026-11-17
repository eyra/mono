defmodule MicaSaas.Frameworks.Pixel.Button.FaceTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias Frameworks.Pixel.Button.Face

  defp face(function, assigns) do
    function
    |> render_component(assigns)
    |> Floki.parse_fragment!()
    |> Floki.find(".prism-button")
    |> then(fn [button] -> button end)
  end

  defp classes(button) do
    button |> Floki.attribute("class") |> hd() |> String.split()
  end

  # The classes of the button's direct children, in order.
  defp parts(button) do
    {_tag, _attrs, children} = button

    for {_child, attrs, _} <- children do
      attrs |> List.keyfind("class", 0) |> elem(1)
    end
  end

  describe "every face renders Prism's button" do
    test "primary_icon" do
      button = face(&Face.primary_icon/1, label: "Add", icon: :add)

      assert ["prism-button", "prism-button--primary", "prism-button--with-icon" | _] =
               classes(button)

      assert parts(button) == ["prism-button__icon", "prism-button__label"]
    end

    test "secondary_icon" do
      button = face(&Face.secondary_icon/1, label: "Add", icon: :add)

      assert ["prism-button", "prism-button--secondary", "prism-button--with-icon" | _] =
               classes(button)
    end

    test "plain_icon puts the icon after the label by default" do
      button = face(&Face.plain_icon/1, label: "Next", icon: :forward)

      assert ["prism-button", "prism-button--plain", "prism-button--with-icon" | _] =
               classes(button)

      assert parts(button) == ["prism-button__label", "prism-button__icon"]
    end

    test "plain_icon puts the icon before the label on the left" do
      button = face(&Face.plain_icon/1, label: "Back", icon: :back, icon_align: :left)

      assert parts(button) == ["prism-button__icon", "prism-button__label"]
    end

    test "label_icon is a compact plain button with the icon first" do
      button = face(&Face.label_icon/1, label: "Copy", icon: :copy)

      assert ["prism-button", "prism-button--plain", "prism-button--with-icon" | _] =
               classes(button)

      assert parts(button) == ["prism-button__icon", "prism-button__label"]
    end

    test "icon" do
      button = face(&Face.icon/1, icon: :close, alt: "Close")

      assert ["prism-button", "prism-button--icon" | _] = classes(button)
      assert [{"img", _, _}] = Floki.find(button, ".prism-button__icon img")
      assert Floki.attribute(button, "img", "alt") == ["Close"]
    end
  end
end
