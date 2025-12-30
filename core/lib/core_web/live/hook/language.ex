defmodule CoreWeb.Live.Hook.Language do
  @moduledoc """
  LiveView hook that applies language/locale from live_context.

  This hook runs after Context hook and checks if the context contains
  a `language` key. If present, it applies the locale for Gettext translations.

  This is primarily used for participant-facing views (CrewPage and its children)
  where the assignment's language setting should override the default locale.
  """

  alias CoreWeb.Live.Hook.Locale

  @session_key "live_context"

  def on_mount(_live_view_module, _params, session, socket) do
    case get_language_from_session(session) do
      nil ->
        {:cont, socket}

      language ->
        Locale.put_locale(language)
        {:cont, socket}
    end
  end

  defp get_language_from_session(session) do
    case Map.get(session, @session_key) do
      nil -> nil
      %{data: %{language: language}} -> language
      _ -> nil
    end
  end
end
