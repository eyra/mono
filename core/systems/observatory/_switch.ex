defmodule Systems.Observatory.Switch do
  @moduledoc """
  Handles Observatory signals for updating LiveViews.

  Supports two signal types:
  - `:routed` - For routed LiveView pages (mounted at router)
  - `:embedded` - For embedded LiveViews (nested within other LiveViews)

  Legacy signals `:page` and `:embedded_live_view` are deprecated but still supported.
  """

  use Frameworks.Signal.Handler

  alias Systems.Observatory

  # New signal format: :routed (for routed LiveView pages)
  def intercept({:routed, live_view}, %{id: id, user_id: user_id} = message) do
    Observatory.Public.dispatch(live_view, [id, user_id], message)
    :ok
  end

  def intercept({:routed, live_view}, %{id: id} = message) do
    Observatory.Public.dispatch(live_view, [id], message)
    :ok
  end

  # New signal format: :embedded (for embedded LiveViews)
  def intercept({:embedded, live_view}, %{id: id, user_id: user_id} = message) do
    Observatory.Public.dispatch(live_view, [id, user_id], message)
    :ok
  end

  def intercept({:embedded, live_view}, %{id: id} = message) do
    Observatory.Public.dispatch(live_view, [id], message)
    :ok
  end

  # DEPRECATED: Use {:routed, page} instead
  def intercept({:page, page}, %{id: id, user_id: user_id} = message) do
    Observatory.Public.dispatch(page, [id, user_id], message)
    :ok
  end

  # DEPRECATED: Use {:routed, page} instead
  def intercept({:page, page}, %{id: id} = message) do
    Observatory.Public.dispatch(page, [id], message)
    :ok
  end

  # DEPRECATED: Use {:embedded, live_view} instead
  def intercept({:embedded_live_view, live_view}, %{id: id, user_id: user_id} = message) do
    Observatory.Public.dispatch(live_view, [id, user_id], message)
    :ok
  end

  # DEPRECATED: Use {:embedded, live_view} instead
  def intercept({:embedded_live_view, live_view}, %{id: id} = message) do
    Observatory.Public.dispatch(live_view, [id], message)
    :ok
  end
end
