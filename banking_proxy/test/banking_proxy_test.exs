defmodule BankingProxyTest do
  use ExUnit.Case
  doctest BankingProxy

  test "greets the world" do
    assert BankingProxy.hello() == :world
  end
end
