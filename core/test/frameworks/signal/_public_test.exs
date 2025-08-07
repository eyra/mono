defmodule Frameworks.Signal.PublicTest do
  use ExUnit.Case

  import Frameworks.Signal.Public

  test "dispatch/2 unhandled signal" do
    assert {:error, :unhandled_signal} = dispatch(:unhandled_signal, %{my_key: :my_value})
  end

  test "dispatch/2 handled signal: ok" do
    assert :ok = dispatch({:force, :ok}, %{my_key: :my_value})
  end

  test "dispatch/2 handled signal: error" do
    assert {:error, :unhandled_signal} = dispatch({:force, :error}, %{my_key: :my_value})
  end

  test "dispatch/2 handled signal: continue" do
    assert :ok = dispatch({:force, :continue}, %{my_key: :my_value})
  end
end
