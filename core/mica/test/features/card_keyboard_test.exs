defmodule MicaWeb.Features.CardKeyboardTest do
  @moduledoc """
  A clickable card can be reached with Tab and opened with Enter or Space
  (WCAG 2.1.1), and shows the `:focus-visible` ring from `assets/css/app.css`.
  The card's show-more toggle is a separate Tab stop that doesn't open the card.
  """
  use MicaWeb.FeatureCase
  use Mica.FeatureFlags.Test

  @card_selector "[data-testid^='card_']"

  @focused """
  const el = document.activeElement;
  if (!el || el === document.body) return null;
  const style = getComputedStyle(el);
  return {
    element: el.outerHTML.slice(0, 200),
    id: el.id,
    testid: el.getAttribute("data-testid"),
    focus_visible: el.matches(":focus-visible"),
    outline: style.outlineStyle !== "none" && parseFloat(style.outlineWidth) > 0
  };
  """

  setup do
    set_feature_flag(:password_sign_in, true)
    password = Factories.valid_user_password()

    user =
      Factories.insert!(:member, %{
        password: password,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        creator: true
      })

    %{user: user, password: password}
  end

  @tag :feature
  feature "a project card and an item card open with the keyboard", %{
    session: session,
    user: user,
    password: password
  } do
    session
    |> resize_window(1440, 900)
    |> sign_in(user, password)
    |> assert_connected("[data-testid='create-first-project-button']")
    |> click(Query.css("[data-testid='create-first-project-button']"))
    |> assert_connected(@card_selector, count: 1)

    project_card = tab_to(session, "card_")
    assert project_card["focus_visible"], "Tab focus is not :focus-visible on the project card"
    assert project_card["outline"], "No focus ring on #{project_card["element"]}"

    session
    |> send_keys([:enter])
    |> assert_connected("[data-testid='create-first-item-button']")
    |> click(Query.css("[data-testid='create-first-item-button']"))
    |> assert_has(Query.css("[data-testid='selector-item-data_donation']"))
    |> click(Query.css("[data-testid='selector-item-data_donation']"))
    |> click(Query.css("[data-testid='create-item-button']"))
    |> assert_connected(@card_selector, count: 1)

    node_path = current_path(session)

    item_card = tab_to(session, "card_")
    assert item_card["outline"], "No focus ring on #{item_card["element"]}"

    session
    |> send_keys([:space])
    |> assert_path_changed_from(node_path)
  end

  @tag :feature
  feature "the show-more toggle is its own Tab stop and doesn't open the card", %{
    session: session,
    user: user,
    password: password
  } do
    session
    |> resize_window(1440, 900)
    |> sign_in(user, password)
    |> assert_connected("[data-testid='create-first-project-button']")
    |> click(Query.css("[data-testid='create-first-project-button']"))
    |> assert_connected(@card_selector, count: 1)

    show_more = tab_to(session, "show_more__action__card_")
    assert show_more["outline"], "No focus ring on #{show_more["element"]}"

    session
    |> send_keys([:enter])
    |> assert_has(Query.css("[data-testid^='rename__action__card_']", visible: true))

    assert current_path(session) == "/project"
    assert_focus(session, &String.ends_with?(&1["id"] || "", "-hide-more"))

    send_keys(session, [:enter])
    assert_focus(session, &(&1["testid"] == show_more["testid"]))
  end

  # Focus moves in the browser after the key press, so poll briefly.
  defp assert_focus(session, matches?, attempts \\ 10) do
    focused = focused(session)

    cond do
      matches?.(focused) ->
        focused

      attempts > 1 ->
        Process.sleep(100)
        assert_focus(session, matches?, attempts - 1)

      true ->
        flunk("Focus is on #{focused["element"] || "the page body"}")
    end
  end

  defp tab_to(session, testid_prefix, max \\ 40) do
    Enum.reduce_while(1..max, nil, fn _, _ ->
      send_keys(session, [:tab])
      focused = focused(session)

      if String.starts_with?(focused["testid"] || "", testid_prefix),
        do: {:halt, focused},
        else: {:cont, nil}
    end) || flunk("Tab never reached an element with data-testid #{testid_prefix}*")
  end

  defp focused(session) do
    execute_script(session, @focused, [], &send(self(), {:focused, &1}))

    receive do
      {:focused, focused} -> focused || %{}
    after
      1_000 -> flunk("The focus probe did not answer")
    end
  end
end
