defmodule NextWeb.Features.RichTextListTest do
  use NextWeb.FeatureCase
  use Mica.FeatureFlags.Test

  alias Next.Systems.Announcement

  @sub_list_item 5
  @bullet_list_item 7

  setup do
    set_feature_flag(:announcements, true)
    set_feature_flag(:password_sign_in, true)
    :ok
  end

  @tag :feature
  feature "a long numbered list keeps each number on one line and indents its sub-lists", %{
    session: session
  } do
    password = "RichTextListFeature123!"
    admin = Factories.insert!(:admin, %{hashed_password: Bcrypt.hash_pwd_salt(password)})

    {:ok, draft} =
      Announcement.Public.create_announcement(admin, %{
        kind: :release_notes,
        title: "List draft",
        summary: "Summary",
        body: list_body()
      })

    published = published!(admin, list_body())

    session
    |> sign_in(admin, password)
    |> visit("/admin/announcement/#{draft.id}")
    |> assert_connected("trix-editor > ol")
    |> assert_list_layout("trix-editor")
    |> visit("/announcement/#{published.id}")
    |> assert_connected("[data-testid=announcement-body] > ol")
    |> assert_list_layout("[data-testid=announcement-body]")
  end

  defp published!(author, body) do
    {:ok, announcement} =
      Announcement.Public.create_announcement(author, %{
        kind: :release_notes,
        title: "List announcement",
        summary: "Summary",
        body: body
      })

    announcement =
      announcement
      |> Ecto.Changeset.change(published_at: DateTime.utc_now() |> DateTime.truncate(:second))
      |> Repo.update!()

    %Announcement.RecipientModel{announcement_id: announcement.id, user_id: author.id}
    |> Announcement.RecipientModel.changeset(%{})
    |> Repo.insert!()

    announcement
  end

  defp list_body do
    items =
      for n <- 1..15 do
        case n do
          @sub_list_item -> "<li>Item #{n}<ol><li>Sub A</li><li>Sub B</li></ol></li>"
          @bullet_list_item -> "<li>Item #{n}<ul><li>Bullet A</li><li>Bullet B</li></ul></li>"
          _ -> "<li>Item #{n}</li>"
        end
      end

    "<ol>#{Enum.join(items)}</ol>"
  end

  # Items without a sub-list are one line high, so a number that wraps onto a
  # second line makes its item taller than the others. A number that doesn't
  # wrap but is wider than its room runs into the text: its width, measured in
  # the number's own font, ends after the start of the text.
  defp assert_list_layout(session, container) do
    execute_script(
      session,
      """
      const items = Array.from(document.querySelector(arguments[0]).querySelector('ol').children);
      const left = (el) => el.getBoundingClientRect().left;
      const textLeft = (li) => {
        const range = document.createRange();
        range.selectNodeContents(
          Array.from(li.childNodes).find((n) => n.nodeType === 3 && n.textContent.trim())
        );
        return range.getBoundingClientRect().left;
      };
      const canvas = document.createElement('canvas').getContext('2d');
      const numberRight = (li, number) => {
        const style = getComputedStyle(li, '::before');
        canvas.font = `${style.fontWeight} ${style.fontSize} ${style.fontFamily}`;
        canvas.letterSpacing = style.letterSpacing;
        return left(li) + parseFloat(style.marginLeft) + canvas.measureText(`${number}.`).width;
      };
      const parent = items[arguments[1] - 1];
      const sub = parent.querySelector('ol > li');
      const bulletParent = items[arguments[2] - 1];
      const bullet = bulletParent.querySelector('ul > li');
      return {
        heights: items
          .filter((li) => !li.querySelector('ol, ul'))
          .map((li) => Math.round(li.getBoundingClientRect().height)),
        text_lefts: items.map((li) => Math.round(textLeft(li) - left(li))),
        gaps: items.map((li, i) => Math.floor(textLeft(li) - numberRight(li, i + 1))),
        sub_indent: left(sub) - left(parent),
        bullet_indent: left(bullet) - left(bulletParent),
        bullet_marker: getComputedStyle(bullet, '::before').content
      };
      """,
      [container, @sub_list_item, @bullet_list_item],
      fn %{
           "heights" => heights,
           "text_lefts" => text_lefts,
           "gaps" => gaps,
           "sub_indent" => sub_indent,
           "bullet_indent" => bullet_indent,
           "bullet_marker" => bullet_marker
         } ->
        assert [height | _] = heights

        assert heights == List.duplicate(height, 13),
               "item heights in #{container}: #{inspect(heights, charlists: :as_lists)}"

        assert [text_left | _] = text_lefts

        assert text_lefts == List.duplicate(text_left, 15),
               "text starts in #{container}: #{inspect(text_lefts, charlists: :as_lists)}"

        assert Enum.all?(gaps, &(&1 >= 0)),
               "number-to-text gaps in #{container}: #{inspect(gaps, charlists: :as_lists)}"

        assert sub_indent > 0
        assert bullet_indent > 0
        assert bullet_marker == ~s("•")
      end
    )
  end
end
