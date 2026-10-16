defmodule Systems.Crew.Factories do
  use Core, :auth
  alias CoreWeb.UI.Timestamp

  def create_member(crew, user, attrs \\ %{}) do
    Core.Factories.insert!(:crew_member, Map.merge(%{crew: crew, user: user}, attrs))
  end

  def create_task(crew, member, [_ | _] = identifier, opts \\ []) do
    {status, opts} = Keyword.pop(opts, :status, :pending)
    {expired, opts} = Keyword.pop(opts, :expired, false)
    {expire_at, opts} = Keyword.pop(opts, :expire_at, nil)
    {minutes_ago, opts} = Keyword.pop(opts, :minutes_ago, 31)

    {updated_at, _opts} =
      Keyword.pop(opts, :expired_at, Timestamp.naive_from_now(minutes_ago * -1))

    auth_node = auth_module().prepare_node(member.user, :owner)

    Core.Factories.insert!(:crew_task, %{
      identifier: identifier,
      crew: crew,
      auth_node: auth_node,
      status: status,
      expired: expired,
      expire_at: expire_at,
      updated_at: updated_at
    })
  end
end
