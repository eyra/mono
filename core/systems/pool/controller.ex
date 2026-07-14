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

  def join(conn, %{"slug" => slug} = params) do
    user = conn.assigns.current_user
    %Pool.Model{} = pool = Pool.Public.get_by_slug(String.to_existing_atom(slug))
    return_to = sanitize_return_to(Map.get(params, "return_to"))

    if Pool.Public.participant?(pool, user) do
      redirect(conn, to: return_to || Account.UserAuth.signed_in_path(user))
    else
      redirect(conn, to: with_return_to(~p"/pool/#{slug}/onboarding", return_to))
    end
  end

  defp sanitize_return_to("/" <> _rest = path), do: path
  defp sanitize_return_to(_), do: nil

  defp with_return_to(path, nil), do: path

  defp with_return_to(path, return_to) do
    "#{path}?return_to=#{URI.encode_www_form(return_to)}"
  end
end
