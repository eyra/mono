defmodule MicaWeb.Features.FocusVisibleTest do
  @moduledoc """
  Keyboard focus is visible on every Tab stop (WCAG 2.4.7), and a mouse click
  adds no ring. The indicator is the `:focus-visible` rule in `assets/css/app.css`.
  """
  use MicaWeb.FeatureCase
  use Mica.FeatureFlags.Test

  alias Systems.Desktop

  @focused """
  const el = document.activeElement;
  if (!el || el === document.body) return null;
  const style = getComputedStyle(el);
  const transparent = (color) => color === "transparent" || /rgba\\(.*,\\s*0\\)$/.test(color);
  const outline =
    style.outlineStyle !== "none" && parseFloat(style.outlineWidth) > 0 && !transparent(style.outlineColor);
  return {
    element: el.outerHTML.slice(0, 200),
    in_menu: el.closest("[data-testid='desktop-menu']") !== null,
    full_list: el.getAttribute("data-testid") === "section-full-list",
    focus_visible: el.matches(":focus-visible"),
    indicator: outline || style.boxShadow !== "none"
  };
  """

  setup do
    set_feature_flag(:password_sign_in, true)
    previous = Mica.SaaS.put_composition(desktop_sections: [Desktop.TestSection])
    on_exit(fn -> Mica.SaaS.put_composition(previous) end)

    put_env(Desktop.TestSection,
      message: "Focus test",
      full_list: %{label: "View all", to: "/desktop"}
    )

    password = Factories.valid_user_password()
    user = Factories.insert!(:creator, %{hashed_password: Bcrypt.hash_pwd_salt(password)})
    %{user: user, password: password}
  end

  @tag :feature
  feature "every Tab stop on the Desktop shows a focus indicator", %{
    session: session,
    user: user,
    password: password
  } do
    session =
      session
      |> resize_window(1440, 900)
      |> sign_in(user, password)
      |> visit("/desktop")
      |> assert_has(css("[data-testid='desktop-menu']"))
      |> assert_has(css("[data-testid='section-full-list']"))

    stops = tab_stops(session, 30)

    assert Enum.count(stops, & &1["in_menu"]) >= 3
    assert Enum.any?(stops, & &1["full_list"])

    for stop <- stops do
      assert stop["focus_visible"], "Tab focus is not :focus-visible on #{stop["element"]}"
      assert stop["indicator"], "No visible focus indicator on #{stop["element"]}"
    end
  end

  @tag :feature
  feature "a mouse click on a menu item shows no focus ring", %{
    session: session,
    user: user,
    password: password
  } do
    session =
      session
      |> resize_window(1440, 900)
      |> sign_in(user, password)
      |> visit("/desktop")
      |> assert_has(css("[data-testid='desktop-menu'] a[data-phx-link]", minimum: 3))
      # Keep the clicked link on the page so its focus can be inspected.
      |> execute_script(
        "document.addEventListener('click', (e) => { e.preventDefault(); e.stopPropagation(); }, true)"
      )
      |> click(css("[data-testid='desktop-menu'] a[data-phx-link]", at: 0))

    focused = focused(session)

    assert focused["in_menu"], "The clicked menu item has no focus: #{inspect(focused)}"
    refute focused["focus_visible"]
    refute focused["indicator"], "A mouse click shows a focus ring on #{focused["element"]}"
  end

  defp tab_stops(session, max) do
    Enum.reduce_while(1..max, [], fn _, stops ->
      send_keys(session, [:tab])
      next_stop(focused(session), stops)
    end)
  end

  defp next_stop(nil, stops), do: {:halt, stops}

  defp next_stop(stop, stops) do
    if stop in stops, do: {:halt, stops}, else: {:cont, stops ++ [stop]}
  end

  defp focused(session) do
    execute_script(session, @focused, [], &send(self(), {:focused, &1}))

    receive do
      {:focused, focused} -> focused
    after
      1_000 -> flunk("The focus probe did not answer")
    end
  end

  defp put_env(key, value) do
    original = Application.get_env(:mica, key)
    Application.put_env(:mica, key, value)
    on_exit(fn -> restore_env(key, original) end)
  end

  defp restore_env(key, nil), do: Application.delete_env(:mica, key)
  defp restore_env(key, original), do: Application.put_env(:mica, key, original)
end
