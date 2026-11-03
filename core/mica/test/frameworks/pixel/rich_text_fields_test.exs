defmodule Frameworks.Pixel.RichTextFieldsTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset, only: [get_change: 2]

  alias Frameworks.Pixel.WysiwygAreaHelpers
  alias Systems.{Consent, Content, Manual, Promotion}

  @dirty ~s|<div onclick="alert(1)"><!--block--><strong>Hi</strong><script>alert(1)</script></div>|
  @clean "<div><strong>Hi</strong></div>"

  describe "every rich-text field is cleaned when it is saved" do
    test "a consent revision's source" do
      changeset = Consent.RevisionModel.changeset(%Consent.RevisionModel{}, %{source: @dirty})
      assert get_change(changeset, :source) == @clean
    end

    test "a content page's body" do
      changeset = Content.PageModel.changeset(%Content.PageModel{}, %{body: @dirty})
      assert get_change(changeset, :body) == @clean
    end

    test "a manual page's text" do
      changeset = Manual.PageModel.changeset(%Manual.PageModel{}, %{text: @dirty})
      assert get_change(changeset, :text) == @clean
    end

    test "a promotion's expectations, description and prerequisites" do
      attrs = %{expectations: @dirty, description: @dirty, prerequisites: @dirty, title: @dirty}

      for type <- [:save, :publish] do
        changeset = Promotion.Model.changeset(%Promotion.Model{}, type, attrs)

        assert get_change(changeset, :expectations) == @clean
        assert get_change(changeset, :description) == @clean
        assert get_change(changeset, :prerequisites) == @clean
        # Plain text, shown escaped.
        assert get_change(changeset, :title) == @dirty
      end
    end
  end

  describe "WysiwygAreaHelpers" do
    test "post_process/1 cleans what the editor sends" do
      assert WysiwygAreaHelpers.post_process(@dirty) == @clean
    end

    test "render_wysiwyg/1 cleans text stored before cleaning existed" do
      assert @dirty |> WysiwygAreaHelpers.render_wysiwyg() |> Phoenix.HTML.safe_to_string() ==
               @clean
    end

    test "render_wysiwyg/1 renders nothing for nil" do
      assert nil |> WysiwygAreaHelpers.render_wysiwyg() |> Phoenix.HTML.safe_to_string() == ""
    end
  end
end
