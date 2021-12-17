defmodule BankingProxy.ProtocolTest do
  use ExUnit.Case, async: true
  import Mox
  alias BankingProxy.Protocol

  @list_payments_message Jason.encode!(%{
                           "call" => "list_payments"
                         }) <> <<31>>

  describe "parse/2" do
    test "creates message" do
      assert Protocol.parse("", ~s({"test": 1}) <> <<31>>) == {"", [%{"test" => 1}]}
    end

    test "allows partial messages" do
      assert {buffer, []} = Protocol.parse("", ~s({"test": 1))
      assert {"", [%{"test" => 1}]} = Protocol.parse(buffer, "}" <> <<31>>)
    end

    test "can parse multiple messages" do
      assert Protocol.parse("", ~s({"test": 1}) <> <<31>> <> ~s({"another": "message"}) <> <<31>>) ==
               {"", [%{"test" => 1}, %{"another" => "message"}]}
    end
  end

  describe "loop/4" do
    test "closes socket on error" do
      MockRanchTransport
      |> expect(:recv, fn _socket, 0, _timeout -> {:error, :closed} end)
      |> expect(:close, fn _socket -> :ok end)

      Protocol.loop(nil, "", nil, MockRanchTransport)
    end

    test "handles a message" do
      MockBankingBackend
      |> expect(:list_payments, fn -> {[], %{}} end)

      MockRanchTransport
      # Receive a message
      |> expect(:recv, fn _socket, 0, _timeout -> {:ok, @list_payments_message} end)
      # It should send a response
      |> expect(:send, fn _socket, _response -> :ok end)
      # Close the loop
      |> expect(:recv, fn _socket, 0, _timeout -> {:error, :closed} end)
      |> expect(:close, fn _socket -> :ok end)

      Protocol.loop(MockBankingBackend, "", nil, MockRanchTransport)
    end
  end

  describe "dispatch_message/2" do
    test "do list_payments" do
    end

    test "return error on unknown call" do
      MockBankingBackend
      |> expect(:list_payments, fn -> nil end)

      assert Protocol.dispatch_message(MockBankingBackend, %{"call" => "undefined_call"}) == %{
               "error" => %{
                 "type" => "undefined",
                 "message" => "Call `undefined_call` is not supported"
               }
             }
    end
  end
end
