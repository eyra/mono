defmodule Frameworks.Signal.TestHelper do
  import ExUnit.Assertions

  @doc """
  Override signal handlers for the current test process.

  Accepts both atoms and strings for module names.

  Example usage in test setup:
      setup do
        Frameworks.Signal.TestHelper.override_signal_handlers([
          Frameworks.Signal.TestHelper,
          Systems.Paper.Switch
        ])

        on_exit(fn ->
          Frameworks.Signal.TestHelper.restore_signal_handlers()
        end)
      end
  """
  def override_signal_handlers(handler_modules) when is_list(handler_modules) do
    string_modules = Enum.map(handler_modules, &module_to_string/1)
    Process.put(:signal_handlers_override, string_modules)
  end

  @doc """
  Restore default signal handlers configuration.
  """
  def restore_signal_handlers do
    Process.delete(:signal_handlers_override)
  end

  @doc """
  Isolate signal handlers for all processes (including nested LiveViews).

  This modifies the Application config to affect ALL processes, not just the test process.
  Automatically registers an on_exit callback to restore the original configuration.

  Must be called from within a test setup block or test case.

  Options:
    - `except: Systems.Paper.Switch` - Also keep the specified switch active
    - `except: [Systems.Paper.Switch, Systems.Assignment.Switch]` - Keep multiple switches active

  Examples:
      setup do
        isolate_signals(except: [Systems.Zircon.Switch])
        # No need for on_exit - it's handled automatically
      end
  """
  def isolate_signals(opts \\ []) do
    # Save original config
    original_config = Application.get_env(:core, :signal)

    # Always include TestRecorder and TestCatchAll
    base_handlers = [
      "Frameworks.Signal.TestRecorder",
      "Frameworks.Signal.TestCatchAll"
    ]

    # Add external handlers from :except option
    additional_handlers =
      case Keyword.get(opts, :except) do
        nil ->
          []

        handler when is_atom(handler) ->
          [module_to_string(handler)]

        handler when is_binary(handler) ->
          [handler]

        handlers when is_list(handlers) ->
          Enum.map(handlers, fn
            h when is_atom(h) -> module_to_string(h)
            h when is_binary(h) -> h
          end)
      end

    new_handlers = base_handlers ++ additional_handlers

    # Set the new configuration
    new_config = Keyword.put(original_config || [], :handlers, new_handlers)
    Application.put_env(:core, :signal, new_config)

    # Also set process-local for the test process itself
    Process.put(:signal_handlers_override, new_handlers)

    # Register cleanup callback
    ExUnit.Callbacks.on_exit(fn ->
      Application.put_env(:core, :signal, original_config || [])
      restore_signal_handlers()
    end)

    :ok
  end

  defmacro assert_signal_dispatched(signal) do
    quote bind_quoted: [signal: signal] do
      {_, {_, message}} = assert_receive({:signal_test, {^signal, _}}, 1000)
      message
    end
  end

  defmacro refute_signal_dispatched(signal) do
    quote bind_quoted: [signal: signal] do
      refute_received({:signal_test, {^signal, _}}, 1000)
    end
  end

  def assert_signals_dispatched(signal, count) do
    for _ <- 1..count do
      assert_signal_dispatched(signal)
    end
  end

  # Private helper to convert module atoms to strings
  defp module_to_string(module) when is_atom(module) do
    module |> Module.split() |> Enum.join(".")
  end

  defp module_to_string(module) when is_binary(module) do
    module
  end
end
