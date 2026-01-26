defmodule Core.SSOHelpers do
  @moduledoc """
  Shared helpers for SSO registration across different providers.

  Handles common error scenarios like duplicate emails gracefully,
  extracting errors from nested changesets and providing consistent
  error handling across SurfConext, Google Sign In, Sign In with Apple, etc.
  """

  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]
  use CoreWeb, :verified_routes

  @doc """
  Handles SSO registration result, redirecting to signin with error flash on failure.

  For successful registration, calls the success callback.
  For failed registration, extracts all errors (including nested changeset errors)
  and redirects to the signin page with error messages.

  ## Examples

      # In a callback plug:
      case MySSO.register_user(user_info) do
        {:ok, sso_user} ->
          log_in_user(config, conn, sso_user.user, true)

        {:error, changeset} ->
          Core.SSOHelpers.handle_registration_error(conn, changeset)
      end

  """
  def handle_registration_error(conn, changeset) do
    errors = collect_errors(changeset)

    Enum.reduce(errors, conn, fn message, conn ->
      put_flash(conn, :error, message)
    end)
    |> redirect(to: ~p"/user/signin")
  end

  @doc """
  Collects all errors from a changeset, including nested changesets.

  Extracts errors from both the parent changeset and any nested `:user` changeset,
  which is common in SSO registration where the SSO user wraps an Account.User.
  """
  def collect_errors(changeset) do
    parent_errors =
      Enum.map(changeset.errors, fn {_, {message, _}} -> message end)

    nested_errors =
      case Ecto.Changeset.get_change(changeset, :user) do
        %Ecto.Changeset{} = user_changeset ->
          Enum.map(user_changeset.errors, fn {field, {message, _}} ->
            "#{field}: #{message}"
          end)

        _ ->
          []
      end

    parent_errors ++ nested_errors
  end
end
