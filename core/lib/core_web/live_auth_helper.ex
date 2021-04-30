defmodule CoreWeb.LiveAssignHelper do
  @moduledoc """
  Automatically setup the current user in LiveViews.
  """
  defmacro __using__(_opts \\ nil) do
    quote do
      @before_compile CoreWeb.LiveAssignHelper
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      defoverridable mount: 3

      defp user(%{"user_token" => user_token}) do
        Core.Accounts.get_user_by_session_token(user_token)
      end

      defp user(_), do: nil

      def mount(params, session, socket) do
        socket =
          socket
          |> Phoenix.LiveView.assign(current_user: user(session))

        super(params, session, socket)
      end
    end
  end
end
