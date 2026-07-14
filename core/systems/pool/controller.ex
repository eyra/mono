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

  alias CoreWeb.ReturnTo
  alias Systems.Pool
  alias Systems.Account

  def join(conn, %{"slug" => slug} = params) do
    user = conn.assigns.current_user
    %Pool.Model{} = pool = Pool.Public.get_by_slug(String.to_existing_atom(slug))
    return_to = ReturnTo.sanitize(Map.get(params, "return_to"))

    if Pool.Public.participant?(pool, user) do
      redirect(conn, to: ReturnTo.resolve(return_to, Account.UserAuth.signed_in_path(user)))
    else
      redirect(conn, to: ReturnTo.append(~p"/pool/#{slug}/onboarding", return_to))
    end
  end
end
