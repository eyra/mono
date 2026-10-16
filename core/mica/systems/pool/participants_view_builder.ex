defmodule Systems.Pool.ParticipantsViewBuilder do
  @moduledoc """
  ViewBuilder for `Pool.ParticipantsView` — read-only list of pool participants.

  Provides:
  - title: section title
  - people: rendered participant rows (avatar, name, email, info), capped at @max_participants
  - participant_count: total after search filter (uncapped) — drives the count next to the title
  - search_placeholder / query_string: powers the SearchBar
  """
  use Gettext, backend: CoreWeb.Gettext

  alias Core.ImageHelpers
  alias CoreWeb.UI.Timestamp
  alias Systems.Account
  alias Systems.Pool

  @max_participants 50

  def view_model(%Pool.Model{} = pool, assigns) do
    query = Map.get(assigns, :query, [])
    query_string = Map.get(assigns, :query_string, "")

    rows = Pool.Public.list_participants_with_added_at(pool)

    filtered =
      rows
      |> filter_by_query(query)
      |> Enum.sort_by(fn {user, _} -> Account.User.label(user) end)

    capped = Enum.take(filtered, @max_participants)

    %{
      title: dgettext("eyra-pool", "participants.title"),
      people: Enum.map(capped, &person_item/1),
      participant_count: length(filtered),
      search_placeholder: dgettext("eyra-pool", "participants.search.placeholder"),
      query_string: query_string
    }
  end

  defp person_item({%Account.User{} = user, added_at}) do
    %{
      photo_url: ImageHelpers.get_photo_url(user.profile),
      name: user.displayname,
      email: user.email,
      info: added_at_label(added_at),
      action_buttons: [mail_button(user)]
    }
  end

  defp mail_button(%Account.User{email: email}) do
    %{
      action: %{type: :http_get, to: "mailto:#{email}"},
      face: %{
        type: :plain,
        label: dgettext("eyra-pool", "participants.email.button"),
        icon: :mail
      }
    }
  end

  defp added_at_label(%NaiveDateTime{} = added_at) do
    date = NaiveDateTime.to_date(added_at)
    "#{dgettext("eyra-pool", "participants.added.label")} #{Timestamp.humanize_date(date)}"
  end

  defp filter_by_query(rows, []), do: rows
  defp filter_by_query(rows, nil), do: rows

  defp filter_by_query(rows, query) when is_list(query) do
    Enum.filter(rows, fn {user, _added_at} -> matches_query?(user, query) end)
  end

  defp matches_query?(_user, []), do: true

  defp matches_query?(user, [term | rest]),
    do: matches_term?(user, term) and matches_query?(user, rest)

  defp matches_term?(_user, ""), do: true

  defp matches_term?(%Account.User{email: email, profile: profile}, term) when is_binary(term) do
    term = String.downcase(term)
    String.contains?(String.downcase(email || ""), term) or profile_matches?(profile, term)
  end

  defp matches_term?(_user, _term), do: false

  defp profile_matches?(%Account.UserProfileModel{fullname: fullname}, term)
       when is_binary(fullname),
       do: String.contains?(String.downcase(fullname), term)

  defp profile_matches?(_profile, _term), do: false
end
