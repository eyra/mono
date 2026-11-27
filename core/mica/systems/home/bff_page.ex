defmodule Systems.Home.BFFPage do
  @moduledoc """
  The BFF's home page: what the web home shows a signed-in user, in the same order and
  behind the same feature flags (`Systems.Home.PageBuilder.block_keys/1`), as a flat
  list of blocks with a `border` around each card after the next best action. Pay out,
  Retry and Donate are not here yet.

  Home shows the first three studies of the marketplace and of the history, then a link
  to the BFF page with all of them (`history/1`, `marketplace/2`). Every block's id
  names what it shows (`"participation/assignment/7"`), so it stays the same while the
  page shows the same thing.
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
  def view_model(user, _params) do
    cards = for key <- PageBuilder.block_keys(user), do: {key, blocks(key, user, @home_limit)}
    {Enum.flat_map(cards, fn {_key, blocks} -> blocks end), Enum.flat_map(cards, &border/1)}
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
  (`Systems.Pool.MarketplaceViewBuilder`): `year` keeps the studies published that
  year, `query` those whose title has every word. The filter's options and the
  search link back to this page, with the other param kept.
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

    # A year the marketplace doesn't have counts as All.
    year = if params[:year] in years, do: params[:year]
    query = params[:query] && String.trim(params[:query])
    cards = Pool.MarketplaceViewBuilder.filtered_cards(items, year, String.split(query || ""))
    heading = marketplace_heading(length(cards), Pool.Model.slug(panl))

    if items == [],
      do: [
        heading,
        %Blocks.Section{
          id: "marketplace-empty",
          body: dgettext("eyra-pool", "marketplace.empty.message")
        }
      ],
      else: [heading, year_filter(years, year, query), search(year, query) | found(cards)]
  end

  defp year_filter(years, year, query) do
    all = %Blocks.FilterOption{
      label: dgettext("eyra-pool", "marketplace.filter.all"),
      to: marketplace_path(nil, query),
      selected: year == nil
    }

    %Blocks.Filter{
      id: "marketplace-filter",
      label: dgettext("eyra-pool", "marketplace.filter.label"),
      options: [
        all
        | for(
            y <- years,
            do: %Blocks.FilterOption{
              label: "#{y}",
              to: marketplace_path(y, query),
              selected: y == year
            }
          )
      ]
    }
  end

  defp search(year, query) do
    %Blocks.Search{
      id: "marketplace-search",
      name: "query",
      to: marketplace_path(year, nil),
      placeholder: dgettext("eyra-pool", "marketplace.search.placeholder"),
      value: if(query != "", do: query)
    }
  end

  defp marketplace_path(year, query) do
    case for {key, value} <- [query: query, year: year], value not in [nil, ""], do: {key, value} do
      [] -> "/bff/page/marketplace"
      params -> "/bff/page/marketplace?" <> URI.encode_query(params, :rfc3986)
    end
  end

  defp found([]),
    do: [
      %Blocks.Section{
        id: "marketplace-none",
        body: dgettext("eyra-pool", "marketplace.filter.none")
      }
    ]

  defp found(cards), do: Enum.map(cards, &advert/1)

  # As on the web home, rewards, marketplace and history each sit in a bordered box.
  defp border({:next_best_action, _blocks}), do: []
  defp border({_key, []}), do: []

  defp border({_key, [%{id: first} | _] = blocks}) do
    %{id: last} = List.last(blocks)
    [%Blocks.Border{start: first, end: last}]
  end

  defp blocks(:next_best_action, user, _limit) do
    case NextAction.Public.next_best_action(user) do
      %{title: title, description: body, cta_label: cta, cta_action: action} ->
        [
          %Blocks.NextBestAction{
            id: "next-best-action",
            title: title,
            body: body,
            cta: cta,
            to: to(action)
          }
        ]

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

  # As on the web home, the marketplace's "See all" shows whenever it has a study: the
  # marketplace page is also where its filters are.
  defp blocks(:panl_marketplace, user, _limit) do
    %{cards: cards, count: count, pool_slug: pool_slug} =
      PageBuilder.panl_marketplace(user, %{current_user: user})

    [marketplace_heading(count, pool_slug) | Enum.map(cards, &advert/1)] ++
      if(count > 0, do: [see_all("marketplace-see-all", "/bff/page/marketplace")], else: [])
  end

  defp blocks(:participated, user, limit) do
    case PageBuilder.participated(user) do
      [] ->
        []

      items ->
        %{title: title} = labels = PageBuilder.participated_labels()
        shown = if limit == :all, do: items, else: Enum.take(items, limit)

        [%Blocks.Section{id: "history", title: title, count: length(items)}] ++
          Enum.map(shown, &participation(&1, labels)) ++
          if(is_integer(limit) and length(items) > limit,
            do: [see_all("history-see-all", "/bff/page/history")],
            else: []
          )
    end
  end

  defp see_all(id, to),
    do: %Blocks.Section{id: id, title: dgettext("eyra-pool", "marketplace.see_all"), to: to}

  defp marketplace_heading(count, pool_slug) do
    %Blocks.Section{
      id: "marketplace",
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
      %Blocks.Section{id: "rewards", title: title},
      %Blocks.RewardAmount{
        id: "rewards-pending",
        label: pending_label,
        tone: :warning,
        amount: CurrencyHelpers.format_cents(pending),
        caption: pending_caption
      },
      %Blocks.RewardAmount{
        id: "rewards-approved",
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
        id: "rewards-rejected",
        label: label,
        tone: :danger,
        amount: CurrencyHelpers.format_cents(cents)
      }
    ]

  defp payout_note(:in_progress, %{payout_in_progress: note}), do: [{"rewards-payout", note}]
  defp payout_note(:manual, %{payout_manual: note}), do: [{"rewards-payout", note}]
  defp payout_note(_status, _labels), do: []

  # As on the web: a donation still being processed hides the donated total.
  defp donation_note(donating, _donated, %{donate_in_progress: note}) when donating > 0,
    do: [{"rewards-donation", note}]

  defp donation_note(_donating, donated, %{donated_total: total}) when donated > 0,
    do: [{"rewards-donation", "#{total} #{CurrencyHelpers.format_cents(donated)}"}]

  defp donation_note(_donating, _donated, _labels), do: []

  defp notes(notes), do: Enum.map(notes, fn {id, note} -> %Blocks.Section{id: id, body: note} end)

  defp advert(%{
         title: title,
         path: path,
         image_info: %{url: image_url},
         icon_url: logo,
         tags: tags,
         info: info
       }) do
    # The spec requires a title and the encoder raises on nil; an untitled study still shows.
    %Blocks.Advert{
      id: "advert" <> path,
      title: title || "",
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
      id: "participation" <> path,
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
  # A notification's button POSTs on the web (`Notify.Public.open_action/2`); the
  # app opens where it leads, which marks nothing seen.
  defp to(%{type: :http_post, destination: destination}), do: destination
  defp to(_action), do: nil
end
