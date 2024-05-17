defmodule CoreWeb.LiveUser do
  @moduledoc """
  Automatically setup the current user in LiveViews.
  """
  def current_user(%{assigns: %{current_user: current_user}}), do: current_user

  def current_user(%{"user_token" => user_token}) do
    Core.Accounts.get_user_by_session_token(user_token)
  end

  def current_user(_), do: nil

  defmacro __using__(_opts \\ nil) do
    quote do
      @before_compile CoreWeb.LiveUser
      import CoreWeb.LiveUser
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defoverridable mount: 3

      def mount(params, session, socket) do
        super(
          params,
          session,
          socket
          |> Phoenix.Component.assign(current_user: current_user(session))
        )
      end
    end
  end
end
