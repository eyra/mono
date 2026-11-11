# `Next.Systems.Graphite.LeaderboardModel`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/graphite/leaderboard_model.ex#L1)

Data model for the `graphite_leaderboard` table.
# Fields
- title: :string, Title of the leaderboard as will be displayed on the platform
- subtitle: :string, Short subtitle for the leaderboard
- status: :enum (?)
- metrics: {:array, :string}, List of metrics that will be tracked for
  leaderboard.
- visibility: Enum with values
  - public: everybody (including anonymous users) can see team names
  - private: team names are hidden for everybody
- open_date: :naive_datetime, datetime after which everybody can see team names
  for the scores on the leaderboard.
- generation_date: :naive_datetime, the day the scores for the leaderboard were
  generated
- tool_id: connects to `Next.Systems.Graphite.ToolModel`
- auth_node_id: connects to `Mica.Authorization.Node`

# `auth_tree`

# `changeset`

# `offline?`

# `online?`

# `preload_graph`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
