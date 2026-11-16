defmodule Systems.Home.BFFPage do
  @moduledoc """
  The BFF's home page: what the web home shows a signed-in user, in the same order and
  behind the same feature flags (`Systems.Home.PageBuilder.block_keys/1`), as a flat
  list of blocks. Pay out, Retry and Donate are not here yet.

  Home shows the first three studies of the marketplace and of the history, then a link
  to the BFF page with all of them (`history/1`, `marketplace/2`).
  """
  @behaviour Systems.BFF.Page

  use Gettext, backend: MicaWeb.Gettext

  alias Frameworks.Pixel.Logo
  alias Systems.Assignment.CurrencyHelpers
  alias Systems.BFF.Blocks
  alias Systems.Home.PageBuilder
  alias Systems.NextAction
  alias Systems.Pool

  @home_limit 3

  @impl true
  def blocks(user, _params) do
    Enum.flat_map(PageBuilder.block_keys(user), &(blocks(&1, user, @home_limit) |> card(&1)))
  end

  @doc "The BFF's history page: every study the user took part in."
  def history(user) do
    if :participated in PageBuilder.block_keys(user),
      do: blocks(:participated, user, :all),
      else: []
  end

  @doc """
  The BFF's marketplace page: every study open to the user in the marketplace Home
  shows, behind the same flags, narrowed down as on the web marketplace
  (`Systems.Pool.MarketplaceViewBuilder`): the `year` filter keeps the studies
  published that year, the `query` search those whose title has every word.
  """
  def marketplace(user, params) do
    if :panl_marketplace in PageBuilder.block_keys(user),
      do: marketplace_blocks(user, params),
      else: []
  end

  defp marketplace_blocks(user, params) do
    panl = Pool.Public.get_panl()

    %{items: items, years: years} =
      Pool.MarketplacePageBuilder.view_model(panl, %{current_user: user})

    year = year(params["year"], years)
    query = query(params["query"])
    cards = Pool.MarketplaceViewBuilder.filtered_cards(items, year, String.split(query || ""))
    heading = marketplace_heading(length(cards), Pool.Model.slug(panl))

    if items == [],
      do: [heading, %Blocks.Section{body: dgettext("eyra-pool", "marketplace.empty.message")}],
      else: [heading, year_filter(years, year), search(query) | found(cards)]
  end

  # A year that isn't one of the marketplace's means no year filter, as "All".
  defp year(value, years) when is_binary(value) do
    case Integer.parse(value) do
      {year, ""} -> if year in years, do: year
      _ -> nil
    end
  end

  defp year(_value, _years), do: nil

  defp query(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      query -> query
    end
  end

  defp query(_value), do: nil

  defp year_filter(years, year) do
    all = %Blocks.FilterOption{
      value: "",
      label: dgettext("eyra-pool", "marketplace.filter.all"),
      selected: year == nil
    }

    %Blocks.Filter{
      name: "year",
      label: dgettext("eyra-pool", "marketplace.filter.label"),
      options: [
        all
        | for(
            y <- years,
            do: %Blocks.FilterOption{value: "#{y}", label: "#{y}", selected: y == year}
          )
      ]
    }
  end

  defp search(query) do
    %Blocks.Search{
      name: "query",
      placeholder: dgettext("eyra-pool", "marketplace.search.placeholder"),
      value: query
    }
  end

  defp found([]), do: [%Blocks.Section{body: dgettext("eyra-pool", "marketplace.filter.none")}]
  defp found(cards), do: Enum.map(cards, &advert/1)

  # As on the web home, rewards, marketplace and history each sit in a bordered box.
  defp card(blocks, :next_best_action), do: blocks
  defp card([], _key), do: []

  defp card(blocks, _key),
    do: [%Blocks.SectionBegin{border: true} | blocks] ++ [%Blocks.SectionEnd{}]

  defp blocks(:next_best_action, user, _limit) do
    case NextAction.Public.next_best_action(user) do
      %{title: title, description: body, cta_label: cta, cta_action: action} ->
        [%Blocks.NextBestAction{title: title, body: body, cta: cta, to: to(action)}]

      nil ->
        []
    end
  end

  defp blocks(:rewards_summary, user, _limit) do
    case PageBuilder.rewards_summary(user) do
      nil -> []
      summary -> rewards(summary)
    end
  end

  defp blocks(:panl_marketplace, user, limit) do
    %{cards: cards, count: count, pool_slug: pool_slug} =
      PageBuilder.panl_marketplace(user, %{current_user: user})

    [marketplace_heading(count, pool_slug) | Enum.map(cards, &advert/1)] ++
      see_all(count, limit, "/bff/page/marketplace")
  end

  defp blocks(:participated, user, limit) do
    case PageBuilder.participated(user) do
      [] ->
        []

      items ->
        %{title: title} = labels = PageBuilder.participated_labels()
        shown = if limit == :all, do: items, else: Enum.take(items, limit)

        [%Blocks.Section{title: title, count: length(items)}] ++
          Enum.map(shown, &participation(&1, labels)) ++
          see_all(length(items), limit, "/bff/page/history")
    end
  end

  # Only home has more than it shows, behind a link to the page with all of them.
  defp see_all(count, limit, to) when is_integer(limit) and count > limit,
    do: [%Blocks.Section{title: dgettext("eyra-pool", "marketplace.see_all"), to: to}]

  defp see_all(_count, _limit, _to), do: []

  defp marketplace_heading(count, pool_slug) do
    %Blocks.Section{
      title: dgettext("eyra-pool", "marketplace.title"),
      body: dgettext("link-advert", "submission.available.sub_heading"),
      count: count,
      image_url: raster_logo(pool_slug)
    }
  end

  defp rewards(%{
         pending_cents: pending,
         approved_cents: approved,
         rejected_cents: rejected,
         donating_cents: donating,
         donated_cents: donated,
         payout_status: payout_status
       }) do
    labels = PageBuilder.rewards_summary_labels(approved)

    amounts(pending, approved, labels) ++
      rejected_amount(rejected, labels) ++
      notes(payout_note(payout_status, labels) ++ donation_note(donating, donated, labels))
  end

  defp amounts(pending, approved, %{
         title: title,
         pending_pill: pending_label,
         pending_caption: pending_caption,
         approved_pill: approved_label,
         approved_caption: approved_caption
       }) do
    [
      %Blocks.Section{title: title},
      %Blocks.RewardAmount{
        label: pending_label,
        tone: :warning,
        amount: CurrencyHelpers.format_cents(pending),
        caption: pending_caption
      },
      %Blocks.RewardAmount{
        label: approved_label,
        tone: :success,
        amount: CurrencyHelpers.format_cents(approved),
        caption: approved_caption
      }
    ]
  end

  defp rejected_amount(0, _labels), do: []

  defp rejected_amount(cents, %{rejected_pill: label}),
    do: [
      %Blocks.RewardAmount{
        label: label,
        tone: :danger,
        amount: CurrencyHelpers.format_cents(cents)
      }
    ]

  defp payout_note(:in_progress, %{payout_in_progress: note}), do: [note]
  defp payout_note(:manual, %{payout_manual: note}), do: [note]
  defp payout_note(_status, _labels), do: []

  # As on the web: a donation still being processed hides the donated total.
  defp donation_note(donating, _donated, %{donate_in_progress: note}) when donating > 0,
    do: [note]

  defp donation_note(_donating, donated, %{donated_total: total}) when donated > 0,
    do: ["#{total} #{CurrencyHelpers.format_cents(donated)}"]

  defp donation_note(_donating, _donated, _labels), do: []

  defp notes(notes), do: Enum.map(notes, &%Blocks.Section{body: &1})

  defp advert(%{
         title: title,
         path: path,
         image_info: %{url: image_url},
         icon_url: logo,
         tags: tags,
         info: info
       }) do
    %Blocks.Advert{
      title: title,
      to: path,
      image_url: image_url,
      logo_url: logo,
      tags: tags,
      info: Enum.join(info, " ")
    }
  end

  defp participation(
         %{
           path: path,
           title: title,
           subtitle: subtitle,
           reward_cents: reward,
           reward_status: status
         },
         %{reward_label: reward_label, status: status_labels}
       ) do
    %Blocks.Participation{
      title: title,
      subtitle: if(subtitle != "", do: subtitle),
      status_label: status_labels[status],
      status_tone: tone(status),
      reward: "#{reward_label} #{CurrencyHelpers.format_cents(reward)}",
      to: path
    }
  end

  defp tone(:awaiting), do: :warning
  defp tone(:approved), do: :success
  defp tone(:rejected), do: :danger
  defp tone(nil), do: nil

  # iOS can't draw an SVG from a URL, so the app gets the PNG next to the pool's wide logo.
  # ponytail: assumes every configured wide pool logo has a .png beside it (only panl_wide today).
  defp raster_logo(pool_slug) do
    with "" <> svg <- Logo.path(pool_slug, {:pool, :wide}) do
      String.replace_suffix(svg, ".svg", ".png")
    end
  end

  defp to(%{type: :redirect, to: to}), do: to
  defp to(_action), do: nil
end
