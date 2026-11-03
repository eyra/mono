defmodule Frameworks.Pixel.Button.FaceTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO
  import Phoenix.LiveViewTest

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Button.Face
  alias Frameworks.Pixel.Prism

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
    test "primary" do
      button = face(&Face.primary/1, label: "Save")

      assert {"div", _, _} = button
      assert classes(button) == ["prism-button", "prism-button--primary"]
      assert parts(button) == ["prism-button__label"]
      assert Floki.text(button) =~ "Save"
    end

    test "primary while loading shows Prism's 20px spinner" do
      button = face(&Face.primary/1, label: "Save", loading: true)

      assert "prism-button--loading" in classes(button)
      assert parts(button) == ["prism-button__label", "prism-spinner prism-spinner--20"]
    end

    test "primary over its full width" do
      assert "w-full" in classes(face(&Face.primary/1, label: "Save", full_width: true))
    end

    test "primary_icon" do
      button = face(&Face.primary_icon/1, label: "Add", icon: :add)

      assert ["prism-button", "prism-button--primary", "prism-button--with-icon" | _] =
               classes(button)

      assert parts(button) == ["prism-button__icon", "prism-button__label"]
    end

    test "secondary" do
      button = face(&Face.secondary/1, label: "Cancel", loading: true)

      assert classes(button) == [
               "prism-button",
               "prism-button--secondary",
               "prism-button--loading"
             ]
    end

    test "secondary_icon" do
      button = face(&Face.secondary_icon/1, label: "Add", icon: :add)

      assert ["prism-button", "prism-button--secondary", "prism-button--with-icon" | _] =
               classes(button)
    end

    test "plain fits its text" do
      button = face(&Face.plain/1, label: "Next")

      assert classes(button) == ["prism-button", "prism-button--plain", "w-full"]
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

    test "label is a padded text button" do
      assert ["prism-button", "prism-button--text", "prism-button--padded" | _] =
               classes(face(&Face.label/1, label: "Edit"))
    end

    test "label fits its text when it wraps" do
      assert ["prism-button", "prism-button--text", "flex", "w-fit"] =
               classes(face(&Face.label/1, label: "Edit", wrap: true))
    end

    test "label_icon is a compact plain button with the icon first" do
      button = face(&Face.label_icon/1, label: "Copy", icon: :copy)

      assert ["prism-button", "prism-button--plain", "prism-button--with-icon" | _] =
               classes(button)

      assert parts(button) == ["prism-button__icon", "prism-button__label"]
    end

    test "link" do
      assert classes(face(&Face.link/1, text: "More")) == ["prism-button", "prism-button--link"]
    end

    test "icon" do
      button = face(&Face.icon/1, icon: :close, alt: "Close")

      assert ["prism-button", "prism-button--icon" | _] = classes(button)
      assert [{"img", _, _}] = Floki.find(button, ".prism-button__icon img")
      assert Floki.attribute(button, "img", "alt") == ["Close"]
    end

    test "a color override follows Prism's classes" do
      button = face(&Face.primary/1, label: "Go", bg_color: "bg-success")

      assert classes(button) == ["prism-button", "prism-button--primary", "bg-success"]
    end
  end

  test "a dynamic button puts the face inside its action" do
    html =
      render_component(&Button.dynamic/1,
        action: %{type: :send, event: "save"},
        face: %{type: :primary, label: "Save"}
      )

    assert [{"div", _, _}] =
             html
             |> Floki.parse_fragment!()
             |> Floki.find(~s([phx-click="save"] .prism-button--primary))
  end

  describe "Prism's variants are checked" do
    test "an unknown variant warns at compile time" do
      warnings =
        capture_io(:stderr, fn ->
          Code.compile_string("""
          defmodule Frameworks.Pixel.Button.FaceTest.Misspelled do
            use Phoenix.Component

            def render(assigns) do
              ~H\"\"\"
              <Frameworks.Pixel.Prism.button variant={:primray}>Save</Frameworks.Pixel.Prism.button>
              \"\"\"
            end
          end
          """)
        end)

      assert warnings =~ ~s(attribute "variant" in component Frameworks.Pixel.Prism.button)
      assert warnings =~ ":primray"
    end

    test "an unknown variant from an assign fails when it renders" do
      assert_raise ArgumentError, fn ->
        render_component(&Prism.button/1, variant: :primray)
      end
    end
  end
end
