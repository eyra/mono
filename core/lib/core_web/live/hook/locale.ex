defmodule CoreWeb.Live.Hook.Locale do
  @moduledoc "A Live Hook that changes the locale of the current process"

  use Frameworks.Concept.LiveHook

  @impl true
  def on_mount(_live_view_module, _params, _session, socket) do
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
