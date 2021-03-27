defmodule LinkWeb.PathProvider do
  alias LinkWeb.Router.Helpers, as: Routes

  def static_path(conn, asset) do
    Routes.static_path(conn, asset)
  end

  def live_path(conn, view) do
    Routes.live_path(conn, view)
  end

  def live_path(conn, view, id) do
    Routes.live_path(conn, view, id)
  end

  def path(conn, controller, view, id \\ nil) do
    case controller do
      CoreWeb.UserSettingsController ->
        case id do
          nil -> Routes.user_settings_path(conn, view)
          id -> Routes.user_settings_path(conn, view, id)
        end

      CoreWeb.UserSessionController ->
        case id do
          nil -> Routes.user_session_path(conn, view)
          id -> Routes.user_session_path(conn, view, id)
        end

      _ ->
        :error
    end
  end

  def path(conn, controller, view, id, opts) do
    case controller do
      CoreWeb.LanguageSwitchController -> Routes.language_switch_path(conn, view, id, opts)
      _ -> :error
    end
  end
end
