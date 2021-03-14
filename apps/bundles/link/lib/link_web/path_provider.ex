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

  def path(conn, controller, view, param \\ nil) do
    case controller do
      CoreWeb.UserSettingsController ->
        case param do
          nil -> Routes.user_settings_path(conn, view)
          param -> Routes.user_settings_path(conn, view, param)
        end

      CoreWeb.UserSessionController ->
        case param do
          nil -> Routes.user_session_path(conn, view)
          param -> Routes.user_session_path(conn, view, param)
        end

      _ ->
        :error
    end
  end

  def path(conn, controller, view, param, opts) do
    case controller do
      CoreWeb.LanguageSwitchController -> Routes.language_switch_path(conn, view, param, opts)
      _ -> :error
    end
  end
end
