defmodule Systems.Pool.MarketplaceViewBuilderTest do
  use ExUnit.Case, async: true

  alias Systems.Pool.MarketplaceViewBuilder

  defp item(title, year \\ 2025), do: %{year: year, card: %{id: 1, title: title, path: "/x"}}

  describe "card_path/2" do
    test "returns {:ok, path} when the card_id matches an item" do
      items = [%{year: 2025, card: %{id: 5, title: "x", path: "/foo/5"}}]

      assert MarketplaceViewBuilder.card_path(items, 5) == {:ok, "/foo/5"}
    end

    test "returns :stale when the card_id is not in items" do
      items = [%{year: 2025, card: %{id: 5, title: "x", path: "/foo/5"}}]

      assert MarketplaceViewBuilder.card_path(items, 99) == :stale
    end

    test "returns :stale on an empty items list" do
      assert MarketplaceViewBuilder.card_path([], 5) == :stale
    end
  end

  describe "filtered_cards/3 — nil/non-string title guard" do
    test "does not crash when an item's card.title is nil and a search is active" do
      items = [item(nil), item("Hello")]

      assert MarketplaceViewBuilder.filtered_cards(items, nil, ["hello"]) ==
               [%{id: 1, title: "Hello", path: "/x"}]
    end

    test "excludes items with nil titles from a non-empty search" do
      items = [item(nil)]

      assert MarketplaceViewBuilder.filtered_cards(items, nil, ["anything"]) == []
    end

    test "excludes items whose title is a non-string from a non-empty search" do
      items = [item(:not_a_string)]

      assert MarketplaceViewBuilder.filtered_cards(items, nil, ["anything"]) == []
    end

    test "keeps nil-title items when no query filter is applied" do
      items = [item(nil)]

      assert MarketplaceViewBuilder.filtered_cards(items, nil, nil) ==
               [%{id: 1, title: nil, path: "/x"}]
    end
  end
end
