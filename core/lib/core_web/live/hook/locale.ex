defmodule CoreWeb.Live.Hook.Locale do
  @moduledoc """
  Live hook that pins the LiveView process's locale.

  The LiveView mount runs in a separate process from the HTTP request,
  so neither Cldr.Plug.PutLocale nor the process-level gettext locale
  from the initial request carries over. Without this hook, every
  LiveView would inherit the BEAM default (`en`) and any page that
  doesn't explicitly call `put_locale/1` would render in English even
  when the session says otherwise.

  Resolution rule:
    * Creators (researchers) always see English.
    * Routed views read the locale from the WebSocket session key
      written by Cldr.Plug.PutLocale / Plug.PersistLocale (or by
      `user_auth.ex` during panl onboarding).
    * Embedded views read the locale stamped into their session by
      `CoreWeb.Live.Element.prepare_live_view/3`, which captures the
      parent process's locale at the moment the embedded view is
      prepared.
    * Falls back to the current Gettext process locale otherwise.
  """

  use Frameworks.Concept.LiveHook

  @impl true
  def mount(_live_view_module, _params, session, socket) do
    locale = resolve_locale(socket.assigns[:current_user], session)
    put_locale(locale)
    {:cont, socket |> Phoenix.Component.assign(locale: locale)}
  end

  defp resolve_locale(%Systems.Account.User{creator: true}, _session), do: "en"

  defp resolve_locale(_user, session) when is_map(session) do
    cldr_key = Cldr.Plug.PutLocale.session_key()

    locale =
      Map.get(session, cldr_key) ||
        Map.get(session, "locale")

    case locale do
      nil -> get_locale()
      locale when is_binary(locale) -> locale
      locale -> to_string(locale)
    end
  end

  defp resolve_locale(_user, _session), do: get_locale()

  def put_locale(locale) when is_atom(locale), do: put_locale(Atom.to_string(locale))

  def put_locale(locale) do
    CoreWeb.Cldr.put_locale(locale)
    Gettext.put_locale(locale)
    Gettext.put_locale(CoreWeb.Gettext, locale)
    Gettext.put_locale(Timex.Gettext, locale)
  end

  def get_locale() do
    Gettext.get_locale()
  end
end

defmodule CoreWeb.Plug.PersistLocale do
  @moduledoc """
  Persists the locale that Cldr.Plug.PutLocale just resolved into the
  session.

  Cldr.Plug.PutLocale sets the locale on gettext/cldr process state but
  doesn't write it back to the session. For anonymous visitors who land
  on the site with an Accept-Language header, that means the LiveView
  mount (which runs in a separate process and reads the session over
  the WebSocket connect_info) can't see the resolved locale and falls
  back to the default — causing a visible NL → EN flash between the
  initial server render and LiveView connect.

  This plug bridges the gap by writing the resolved locale into the
  same session key Cldr.Plug.PutLocale reads from.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case Cldr.Plug.PutLocale.get_cldr_locale(conn) do
      %Cldr.LanguageTag{cldr_locale_name: name} when not is_nil(name) ->
        put_session(conn, Cldr.Plug.PutLocale.session_key(), to_string(name))

      _ ->
        conn
    end
  end
end
