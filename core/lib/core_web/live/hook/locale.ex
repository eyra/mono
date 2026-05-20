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
    * Read the locale from the session — written by Cldr.Plug.PutLocale
      / Plug.PersistLocale for routed views, or stamped by
      Live.Element.prepare_live_view for embedded views.
    * Validate it against the configured Cldr set; fall back to English
      otherwise.

  The user-aware decision (EN unless the request is in participant
  context) lives entirely in `CoreWeb.Plug.ResolveLocale`; this hook
  just trusts the session.
  """

  use Frameworks.Concept.LiveHook

  @cldr_locales CoreWeb.Cldr.known_locale_names() |> Enum.map(&Atom.to_string/1)
  @default_locale "en"

  @impl true
  def mount(_live_view_module, _params, session, socket) do
    locale = resolve_locale(session)
    put_locale(locale)
    {:cont, socket |> Phoenix.Component.assign(locale: locale)}
  end

  defp resolve_locale(session) do
    case session_locale(session) do
      locale when locale in @cldr_locales -> locale
      _ -> @default_locale
    end
  end

  defp session_locale(session) when is_map(session) do
    cldr_key = Cldr.Plug.PutLocale.session_key()

    case Map.get(session, cldr_key) || Map.get(session, "locale") do
      nil -> nil
      locale when is_binary(locale) -> locale
      locale -> to_string(locale)
    end
  end

  defp session_locale(_), do: nil

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

defmodule CoreWeb.Plug.ResolveLocale do
  @moduledoc """
  Forces the session locale to English for any request that is not made
  in a "participant context", so the rest of the locale pipeline (Cldr,
  Hook.Locale, Gettext) can simply read the session.

  Participant context covers:
    * A logged-in participant (`%Account.User{creator: false}`).
    * The participant signup route (`/user/signup/participant`), where
      the visitor is anonymous but intends to become a participant and
      should see the page in their browser language.

  Runs after `Systems.Account.Plug` (which assigns `current_user`) and
  before `Cldr.Plug.PutLocale` (which reads the session). For
  participant contexts the session is left untouched so Cldr can keep
  resolving from session / Accept-Language. For everyone else the
  session locale is pinned to "en", which keeps the initial HTTP render
  and the subsequent LiveView mount agreeing on the locale (no
  EN→non-EN flash for creators / anonymous visitors).
  """
  import Plug.Conn

  @participant_path_prefixes ["/user/signup/participant", "/user/onboarding"]

  def init(opts), do: opts

  def call(conn, _opts) do
    if participant_context?(conn) do
      conn
    else
      put_session(conn, Cldr.Plug.PutLocale.session_key(), "en")
    end
  end

  defp participant_context?(%{assigns: %{current_user: %Systems.Account.User{creator: false}}}),
    do: true

  defp participant_context?(%{request_path: path}) when is_binary(path),
    do: Enum.any?(@participant_path_prefixes, &String.starts_with?(path, &1))

  defp participant_context?(_), do: false
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
