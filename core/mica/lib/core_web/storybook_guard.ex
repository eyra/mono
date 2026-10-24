defmodule CoreWeb.StorybookGuard do
  @moduledoc """
  Opens the component storybooks to admins, and only while the `:storybook` feature is on.
  Prod never turns the feature on (see `Core.RuntimeConfig.features/2`).
  """
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  alias Systems.Admin

  def init(opts), do: opts

  def call(%{assigns: assigns} = conn, _opts) do
    cond do
      not Core.FeatureFlags.conf_enabled?(:storybook) ->
        conn |> send_resp(404, "Not Found") |> halt()

      Admin.Public.admin?(assigns[:current_user]) ->
        conn

      true ->
        conn |> redirect(to: "/access_denied") |> halt()
    end
  end
end
