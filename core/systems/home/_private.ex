defmodule Systems.Home.Private do
  @moduledoc """
  Internal helpers for the Home system — shared by `Systems.Home.Page` and
  `Systems.Home.StudiesPage`.
  """

  alias Systems.Account
  alias Systems.Pool

  @doc """
  Pins the LiveView process's locale to Dutch for panl participants
  (non-creator panl members) and English for everyone else.

  Lives here rather than in the view-model builder so the builder stays
  a pure data function. Call from each home LiveView's `mount/3`.
  """
  def apply_panl_locale(%Account.User{creator: false} = user) do
    locale = if Pool.Public.participant?(:panl, user), do: "nl", else: "en"
    CoreWeb.Live.Hook.Locale.put_locale(locale)
  end

  def apply_panl_locale(_), do: CoreWeb.Live.Hook.Locale.put_locale("en")
end
