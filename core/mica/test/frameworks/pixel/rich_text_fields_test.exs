defmodule Frameworks.Pixel.RichTextFieldsTest.Form do
  use Phoenix.LiveComponent
  use Frameworks.Pixel.WysiwygAreaHelpers

  alias Systems.Content

  @impl true
  def handle_wysiwyg_update(%{assigns: %{body: body}} = socket) do
    assign(socket, changeset: Content.PageModel.changeset(%Content.PageModel{}, %{body: body}))
  end

  @impl true
  def render(assigns), do: ~H"<div></div>"
end

defmodule Frameworks.Pixel.RichTextFieldsTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset, only: [get_change: 2]
  import Mica.DataCase, only: [errors_on: 1]

  alias Frameworks.Pixel.RichText
  alias Frameworks.Pixel.WysiwygAreaHelpers
  alias Systems.Consent
  alias Systems.Content
  alias Systems.Manual
  alias Systems.Promotion

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

  describe "a rich-text field's size" do
    test "up to the limit is accepted" do
      body = String.duplicate("a", RichText.max_bytes())
      changeset = Content.PageModel.changeset(%Content.PageModel{}, %{body: body})

      assert changeset.valid?
    end

    test "over the limit is an error" do
      body = String.duplicate("a", RichText.max_bytes() + 1)
      changeset = Content.PageModel.changeset(%Content.PageModel{}, %{body: body})

      assert %{body: ["should be at most 2000000 byte(s)"]} = errors_on(changeset)
    end

    test "over the limit isn't cleaned" do
      body = "<script>x</script>" <> String.duplicate("a", RichText.max_bytes())
      changeset = Content.PageModel.changeset(%Content.PageModel{}, %{body: body})

      assert get_change(changeset, :body) == body
    end
  end

  describe "a rich-text field's size once cleaned" do
    # A paragraph as the editor writes it. Cleaning adds `target="_blank"` to
    # the link and writes `<br>` as `<br />`, so it grows by about 15%.
    @paragraph ~s|<div>Some <strong>bold</strong> and <em>italic</em> text with | <>
                 ~s|<a href="https://example.org/docs">a link</a>.<br>Next line</div>|

    test "over the limit because every & is written as &amp; is an error" do
      body = String.duplicate("&", RichText.max_bytes())
      changeset = Content.PageModel.changeset(%Content.PageModel{}, %{body: body})

      assert %{body: ["should be at most 2000000 byte(s)"]} = errors_on(changeset)
    end

    test "over the limit because every < is written as &lt; is an error" do
      body = String.duplicate("<", RichText.max_bytes())
      changeset = Content.PageModel.changeset(%Content.PageModel{}, %{body: body})

      assert %{body: ["should be at most 2000000 byte(s)"]} = errors_on(changeset)
    end

    test "of the editor's text that ends up just within the limit is accepted" do
      count = div(RichText.max_bytes(), byte_size(RichText.clean(@paragraph)))
      body = String.duplicate(@paragraph, count)
      changeset = Content.PageModel.changeset(%Content.PageModel{}, %{body: body})

      # About 1.75 MB as sent, just under 2 MB once cleaned.
      assert byte_size(body) < 1_800_000
      assert byte_size(get_change(changeset, :body)) in 1_990_000..RichText.max_bytes()
      assert changeset.valid?
    end

    test "of the editor's text that is within the limit as sent but not once cleaned is an error" do
      count = div(RichText.max_bytes(), byte_size(@paragraph))
      body = String.duplicate(@paragraph, count)
      changeset = Content.PageModel.changeset(%Content.PageModel{}, %{body: body})

      # Just under 2 MB as sent, about 2.3 MB once cleaned.
      assert byte_size(body) in 1_990_000..RichText.max_bytes()
      assert %{body: ["should be at most 2000000 byte(s)"]} = errors_on(changeset)
    end
  end

  describe "stored text over the limit" do
    test "is shown up to the limit" do
      text = "<div>" <> String.duplicate("a", RichText.max_bytes() * 2) <> "</div>"
      shown = text |> WysiwygAreaHelpers.render_wysiwyg() |> Phoenix.HTML.safe_to_string()

      assert shown == "<div>" <> String.duplicate("a", RichText.max_bytes() - 5) <> "</div>"
    end

    test "is cut at a character, not inside one" do
      text = "a" <> String.duplicate("é", RichText.max_bytes())
      shown = RichText.clean_stored(text)

      assert String.valid?(shown)
      assert shown == "a" <> String.duplicate("é", div(RichText.max_bytes() - 1, 2))
    end
  end

  describe "a reference that isn't a character" do
    test "is saved as U+FFFD" do
      changeset =
        Content.PageModel.changeset(%Content.PageModel{}, %{body: "<div>&#x110000;</div>"})

      assert changeset.valid?
      assert get_change(changeset, :body) == "<div>\uFFFD</div>"
    end

    test "is shown as U+FFFD" do
      assert "<div>&#1114112;</div>"
             |> WysiwygAreaHelpers.render_wysiwyg()
             |> Phoenix.HTML.safe_to_string() == "<div>\uFFFD</div>"
    end
  end

  describe "the editor's save event" do
    test "with text over the limit returns the error and leaves the text as sent" do
      body = "<script>x</script>" <> String.duplicate("a", RichText.max_bytes())

      {:noreply, %{assigns: %{body: assigned, changeset: changeset}}} =
        __MODULE__.Form.handle_event(
          "save_wysiwyg",
          %{"_target" => ["body_input"], "body_input" => body},
          %Phoenix.LiveView.Socket{}
        )

      assert assigned == body
      assert %{body: ["should be at most 2000000 byte(s)"]} = errors_on(changeset)
    end

    test "with text within the limit cleans it" do
      {:noreply, %{assigns: %{body: assigned, changeset: changeset}}} =
        __MODULE__.Form.handle_event(
          "save_wysiwyg",
          %{"_target" => ["body_input"], "body_input" => @dirty},
          %Phoenix.LiveView.Socket{}
        )

      assert assigned == @clean
      assert changeset.valid?
    end
  end

  describe "WysiwygAreaHelpers" do
    test "post_process/1 leaves text over the limit as it is" do
      body = "<script>x</script>" <> String.duplicate("a", RichText.max_bytes())
      assert WysiwygAreaHelpers.post_process(body) == body
    end

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
