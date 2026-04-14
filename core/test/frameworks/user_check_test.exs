defmodule Frameworks.UserCheckTest do
  use ExUnit.Case, async: true

  alias Frameworks.UserCheck
  alias Frameworks.UserCheck.ResultModel

  describe "check_email/1 with MockClient" do
    test "returns valid result for normal email" do
      assert {:ok, %ResultModel{disposable: false, mx: true, blocklisted: false}} =
               UserCheck.check_email("user@example.com")
    end

    test "detects disposable email" do
      assert {:ok, %ResultModel{disposable: true}} =
               UserCheck.check_email("disposable@tempmail.com")
    end

    test "detects role account" do
      assert {:ok, %ResultModel{role_account: true}} =
               UserCheck.check_email("role@company.com")
    end

    test "detects blocklisted email" do
      assert {:ok, %ResultModel{blocklisted: true}} =
               UserCheck.check_email("blocklisted@badactor.com")
    end

    test "detects invalid MX" do
      assert {:ok, %ResultModel{mx: false}} =
               UserCheck.check_email("nomx@nonexistent.com")
    end

    test "detects spam email" do
      assert {:ok, %ResultModel{spam: true}} =
               UserCheck.check_email("spam@spammer.com")
    end

    test "suggests correction for typo" do
      assert {:ok, %ResultModel{did_you_mean: "typo@gmail.com"}} =
               UserCheck.check_email("typo@gmial.com")
    end

    test "detects public domain" do
      assert {:ok, %ResultModel{public_domain: true}} =
               UserCheck.check_email("public@gmail.com")
    end

    test "detects alias" do
      assert {:ok, %ResultModel{alias: true}} =
               UserCheck.check_email("alias+tag@gmail.com")
    end

    test "returns error for error@ prefix" do
      assert {:error, :timeout} = UserCheck.check_email("error@example.com")
    end
  end
end
