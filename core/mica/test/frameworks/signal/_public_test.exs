defmodule Frameworks.Signal.PublicTest do
  use ExUnit.Case

  import Frameworks.Signal.Public
  import Frameworks.Signal.TestHelper, only: [override_signal_handlers: 1]

  describe "without any handlers" do
    setup do
      override_signal_handlers([])
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
      override_signal_handlers([Frameworks.Signal.TestForceSwitch])
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
