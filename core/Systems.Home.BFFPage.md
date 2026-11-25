# `Systems.Home.BFFPage`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/home/bff_page.ex#L1)

The BFF's home page: what the web home shows a signed-in user, in the same order and
behind the same feature flags (`Systems.Home.PageBuilder.block_keys/1`), as a flat
list of blocks with a `border` around each card after the next best action. Pay out,
Retry and Donate are not here yet.

Home shows the first three studies of the marketplace and of the history, then a link
to the BFF page with all of them (`history/1`, `marketplace/2`). Every block's id
names what it shows (`"participation/assignment/7"`), so it stays the same while the
page shows the same thing.

# `history`

The BFF's history page: every study the user took part in.

# `marketplace`

The BFF's marketplace page: every study open to the user in the marketplace Home
shows, behind the same flags, narrowed down as on the web marketplace
(`Systems.Pool.MarketplaceViewBuilder`): `year` keeps the studies published that
year, `query` those whose title has every word. The filter's options and the
search link back to this page, with the other param kept.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
