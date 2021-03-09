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

  def path(conn, controller, view) do
    case controller do
      CoreWeb.UserSettingsController -> Routes.user_settings_path(conn, view)
      CoreWeb.UserSessionController -> Routes.user_session_path(conn, view)
      _ -> Routes.live_path(conn, CoreWeb.Dashboard)
    end
  end

  def path(conn, controller, view, param, opts) do
    case controller do
      CoreWeb.LanguageSwitchController -> Routes.language_switch_path(conn, view, param, opts)
      _ -> Routes.live_path(conn, CoreWeb.Dashboard)
    end
  end
end
