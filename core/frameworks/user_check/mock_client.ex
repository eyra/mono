defmodule Frameworks.UserCheck.MockClient do
  @moduledoc """
  Deterministic mock client for dev and test environments.

  Returns predictable results based on email prefix patterns:
  - `disposable@*` → disposable: true
  - `role@*` → role_account: true
  - `blocklisted@*` → blocklisted: true
  - `nomx@*` → mx: false
  - `spam@*` → spam: true
  - `typo@gmial.com` → did_you_mean: "typo@gmail.com"
  - Everything else → valid email, all checks pass
  """

  @behaviour Frameworks.UserCheck.Client

  alias Frameworks.UserCheck.ResultModel

  @impl true
  def check_email("disposable@" <> _) do
    {:ok, %ResultModel{valid_result() | disposable: true}}
  end

  def check_email("role@" <> _) do
    {:ok, %ResultModel{valid_result() | role_account: true}}
  end

  def check_email("blocklisted@" <> _) do
    {:ok, %ResultModel{valid_result() | blocklisted: true}}
  end

  def check_email("nomx@" <> _) do
    {:ok, %ResultModel{valid_result() | mx: false}}
  end

  def check_email("spam@" <> _) do
    {:ok, %ResultModel{valid_result() | spam: true}}
  end

  def check_email("typo@gmial.com") do
    {:ok, %ResultModel{valid_result() | did_you_mean: "typo@gmail.com"}}
  end

  def check_email("public@gmail.com") do
    {:ok, %ResultModel{valid_result() | public_domain: true}}
  end

  def check_email("alias+tag@" <> _) do
    {:ok, %ResultModel{valid_result() | alias: true}}
  end

  def check_email("error@" <> _) do
    {:error, :timeout}
  end

  def check_email(_email) do
    {:ok, valid_result()}
  end

  defp valid_result do
    %ResultModel{
      disposable: false,
      mx: true,
      blocklisted: false,
      role_account: false,
      public_domain: false,
      alias: false,
      spam: false,
      did_you_mean: nil,
      raw: %{
        "status" => 200,
        "disposable" => false,
        "mx" => true,
        "blocklisted" => false,
        "role_account" => false,
        "public_domain" => false,
        "relay_domain" => false,
        "alias" => false,
        "spam" => false,
        "did_you_mean" => nil,
        "domain_authority" => 50,
        "domain_age_in_days" => 3650
      }
    }
  end
end
