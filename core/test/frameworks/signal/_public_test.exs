defmodule Frameworks.Signal.PublicTest do
  use ExUnit.Case

  import Frameworks.Signal.Public

  describe "without any handlers" do
    setup do
      # Save original config and clear all handlers
      original_config = Application.get_env(:core, :signal)
      Application.put_env(:core, :signal, handlers: [])

      on_exit(fn ->
        Application.put_env(:core, :signal, original_config || [])
      end)
    end

    test "dispatch/2 unhandled signal" do
      assert {:error, :unhandled_signal} = dispatch(:unhandled_signal, %{my_key: :my_value})
    end

    test "dispatch/2 unhandled signal with different signal" do
      assert {:error, :unhandled_signal} = dispatch(:some_other_signal, %{})
    end
  end

  describe "with TestForceSwitch only" do
    setup do
      # Set only TestForceSwitch as handler
      original_config = Application.get_env(:core, :signal)
      Application.put_env(:core, :signal, handlers: ["Frameworks.Signal.TestForceSwitch"])

      on_exit(fn ->
        Application.put_env(:core, :signal, original_config || [])
      end)
    end

    test "dispatch/2 handled signal: ok" do
      assert :ok = dispatch({:force, :ok}, %{my_key: :my_value})
    end

    test "dispatch/2 handled signal: error" do
      assert {:error, :force_error} = dispatch({:force, :error}, %{my_key: :my_value})
    end

    test "dispatch/2 handled signal: continue" do
      assert :ok = dispatch({:force, :continue}, %{my_key: :my_value})
    end
  end
end
