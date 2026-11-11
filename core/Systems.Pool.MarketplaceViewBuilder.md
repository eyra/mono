# `Systems.Pool.MarketplaceViewBuilder`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/pool/marketplace_view_builder.ex#L1)

# `card_path`

Returns `{:ok, path}` for the card with the given id, or `:stale` if the
card no longer appears in `items` (e.g. it was filtered out between
render and click).

# `filtered_cards`

Filters the marketplace items by year and free-text query, returning the
underlying cards in the original order.

# `view_model`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
