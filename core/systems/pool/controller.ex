defmodule Systems.Pool.Controller do
  @moduledoc """
  Phoenix controller for Pool-scoped HTTP entry points that are not
  themselves LiveViews.

  Currently exposes:

    * `join/2` — gate at `/pool/:slug/join`. Resolves the slug, checks
      whether the current user is already a participant, and either
      forwards to the pool-scoped onboarding LiveView or redirects
      home.
  """
  use CoreWeb, {:controller, [formats: [:html]]}

  alias Systems.Pool
  alias Systems.Account

  def join(conn, %{"slug" => slug}) do
    user = conn.assigns.current_user
    %Pool.Model{} = pool = Pool.Public.get_by_slug(String.to_existing_atom(slug))

    if Pool.Public.participant?(pool, user) do
      redirect(conn, to: Account.UserAuth.signed_in_path(user))
    else
      redirect(conn, to: ~p"/pool/#{slug}/onboarding")
    end
  end
end
