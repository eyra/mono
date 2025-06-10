defmodule CoreWeb.Validator.Plug do
  @moduledoc """
  A plug to validate input path/query params on your routers.

  Usage:

      plug CoreWeb.Validator.Plug, on_error: &MyApp.Validators.on_error_fn/2

  Example route registration:

      scope "/assignment", Systems.Assignment do
        pipe_through([:browser_unprotected, :validator])

        post("/:id/:entry", AffiliateController, :create,
          private: %{
            validate: %{
              id: &Systems.Validators.Integer.valid_integer?/1,
              entry: &Systems.Validators.String.valid_non_empty?/1
            },
            validation_handler:
              &Systems.Assignment.AffiliateController.validation_error_callback/2
          }
        )
      end
  """

  alias Plug.Conn
  require Logger

  def init(opts), do: opts

  @doc """
  Validates the parameters from the connection.

  If validations (provided via the route's private map) fail,
  it calls the provided `on_error` callback with the connection and errors.
  """
  def call(conn, opts) do
    case conn.private[:validate] do
      nil ->
        conn

      validations ->
        conn = Conn.fetch_query_params(conn)
        errors = validations |> collect_errors(conn)

        if map_size(errors) > 0 do
          handle_validation_error(conn, errors, opts)
        else
          conn
        end
    end
  end

  defp collect_errors(validations, conn) do
    Enum.reduce(validations, %{}, fn {field, validator}, acc ->
      # Convert atom key to string to match the conn.params keys
      value = Map.get(conn.params, to_string(field))

      case validator.(value) do
        {:error, msg} -> Map.put(acc, field, msg)
        _ -> acc
      end
    end)
  end

  # Lookup or use the provided error handler
  defp handle_validation_error(conn, errors, opts) do
    cond do
      handler = opts[:on_error] ->
        handler.(conn, errors)

      handler = conn.private[:validation_handler] ->
        cond do
          is_function(handler, 2) ->
            handler.(conn, errors)

          is_atom(handler) and function_exported?(handler, :validation_error_callback, 2) ->
            apply(handler, :validation_error_callback, [conn, errors])

          true ->
            default_error_handler(conn, errors)
        end

      true ->
        default_error_handler(conn, errors)
    end
  end

  # Default error handling behavior
  defp default_error_handler(conn, _errors) do
    conn
    |> Conn.put_status(:not_found)
    |> Phoenix.Controller.put_view(CoreWeb.ErrorHTML)
    |> Phoenix.Controller.render("404.html")
    |> Conn.halt()
  end
end
