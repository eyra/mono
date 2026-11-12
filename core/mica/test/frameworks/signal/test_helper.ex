defmodule Frameworks.Signal.TestHelper do
  import ExUnit.Assertions

  @doc """
  Replaces the signal handlers of the composition for every process, until the
  test ends (`Mica.SaaS.put_composition/1`). The test must not be `async`.

  Accepts both atoms and strings for module names.

      setup do
        Frameworks.Signal.TestHelper.override_signal_handlers([
          Frameworks.Signal.TestHelper,
          Next.Systems.Paper.Switch
        ])
      end
  """
  def override_signal_handlers(handler_modules) when is_list(handler_modules) do
    previous = Mica.SaaS.put_composition(signal_handlers: Enum.map(handler_modules, &to_module/1))
    ExUnit.Callbacks.on_exit(fn -> Mica.SaaS.put_composition(previous) end)
    :ok
  end

  @doc "Puts back the signal handlers of the composition's systems."
  def restore_signal_handlers do
    Mica.SaaS.put_composition(
      signal_handlers: Mica.SaaS.collect_signal_handlers(Mica.SaaS.systems())
    )

    :ok
  end

  @doc """
  Isolate signal handlers for all processes (including nested LiveViews): only
  the test recorder and catch-all handle signals, until the test ends.

  Must be called from within a test setup block or test case.

  Options:
    - `except: Next.Systems.Paper.Switch` - Also keep the specified switch active
    - `except: [Next.Systems.Paper.Switch, Systems.Assignment.Switch]` - Keep multiple switches active

  Examples:
      setup do
        isolate_signals(except: [Next.Systems.Zircon.Switch])
        # No need for on_exit - it's handled automatically
      end
  """
  def isolate_signals(opts \\ []) do
    base_handlers = [Frameworks.Signal.TestRecorder, Frameworks.Signal.TestCatchAll]
    override_signal_handlers(base_handlers ++ List.wrap(Keyword.get(opts, :except)))
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

  defp to_module(module) when is_atom(module), do: module
  defp to_module(module) when is_binary(module), do: Module.concat([module])
end
