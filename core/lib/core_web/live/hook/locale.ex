defmodule CoreWeb.Live.Hook.Locale do
  @moduledoc "A Live Hook that changes the locale of the current process"

  use Frameworks.Concept.LiveHook

  @impl true
  def mount(_live_view_module, _params, _session, socket) do
    {:cont, socket |> Phoenix.Component.assign(locale: CoreWeb.Live.Hook.Locale.get_locale())}
  end

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
