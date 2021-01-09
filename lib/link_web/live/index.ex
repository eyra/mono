defmodule LinkWeb.Index do
  use LinkWeb, :live_view
  use LinkWeb.LiveViewPowHelper
  import Link.Users

  def mount(_params, session, socket) do
    user = get_user(socket, session)
    profile = get_profile(user)
    socket = assign_current_user(socket, session, user, profile)
    {:ok, socket}
  end
end
