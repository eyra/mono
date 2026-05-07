defmodule Frameworks.Signal.Public do
  use Core, :public
  require Logger

  import Frameworks.Utility.PrettyPrint

  alias Frameworks.Signal.Private

  def dispatch(signal, message) do
    message = Map.put_new(message, :from_pid, self())

    case Private.dispatch(signal, message) do
      {:error, _} = error ->
        Logger.warning(
          "Unhandled signal: #{pretty_print(signal)} => #{pretty_print(Map.keys(message))}, FROM: #{inspect(Map.get(message, :from_pid))}"
        )

        error

      other ->
        other
    end
  end

  @doc """
  # Deprecated, replaced by control flow in intercept/2
  #
  # Implement intercept/2 in your Signal Handler like this instead:
  #
  # ```elixir
  # def intercept({my_entity, :updated}, %{my_entity: my_entity}) do
  #   my_tool = get_my_tool_by_my_entity!(my_entity)
  #   {:continue, :my_tool, my_tool}
  # end
  # ```
  """
  def dispatch!(signal, message) do
    dispatch(signal, message)
  end

  @doc """
  Send a signal as part of an Ecto Multi.
  It automatically merges the message with the multi
  changes.

  ## Options
    - `:name` - The operation name to use in the Multi (defaults to :dispatch_signal)
    - `:message` - Additional message data to merge with the Multi changes (defaults to %{})

  ## Examples
      multi
      |> Signal.Public.multi_dispatch({:user, :created})

      multi
      |> Signal.Public.multi_dispatch({:user, :updated}, name: :dispatch_user_signal)

      multi
      |> Signal.Public.multi_dispatch({:user, :deleted},
          name: :dispatch_delete_signal,
          message: %{deleted_by: admin_id})
  """
  def multi_dispatch(multi, signal, opts \\ []) do
    operation_name = Keyword.get(opts, :name, :dispatch_signal)
    message = Keyword.get(opts, :message, %{})

    Ecto.Multi.run(multi, operation_name, fn _, updates ->
      case dispatch(signal, Map.merge(updates, message)) do
        :ok ->
          {:ok, message}

        {:error, :unhandled_signal} ->
          # Log but don't fail the transaction if signal is unhandled
          # This can happen in development/test environments
          {:ok, message}

        error ->
          error
      end
    end)
  end

  # Deprecated: Keep for backwards compatibility
  def multi_dispatch(multi, signal, message, opts) when is_map(message) and is_list(opts) do
    multi_dispatch(multi, signal, Keyword.put(opts, :message, message))
  end
end
