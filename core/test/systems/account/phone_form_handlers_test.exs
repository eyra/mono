defmodule Systems.Account.PhoneFormHandlersTest do
  @moduledoc """
  White-box coverage of PhoneForm's submit handler. The form renders inside a
  modal, so instead of a LiveView render cycle we call handle_event/3 directly
  and assert the error the participant is left with.

  A provider failure used to collapse into one generic "try again later", hiding
  the case the participant can actually fix — a number OPP rejected.
  """
  use Core.DataCase
  import Mox

  alias Core.Factories
  alias Systems.Account
  alias Systems.Payment.ProviderMock

  setup :verify_on_exit!

  defp t(key), do: Gettext.dgettext(CoreWeb.Gettext, "eyra-account", key)

  defp socket(user) do
    %Phoenix.LiveView.Socket{
      assigns: %{
        __changed__: %{},
        fabric: Fabric.Factories.create_fabric(),
        myself: %Phoenix.LiveComponent.CID{cid: 1},
        id: :phone_form,
        user: user,
        changeset: Account.User.phone_changeset(user, %{}),
        error: nil
      }
    }
  end

  defp submit(user) do
    {:noreply, socket} =
      Account.PhoneForm.handle_event(
        "submit",
        %{"user" => %{"phone" => "+31612345678"}},
        socket(user)
      )

    socket
  end

  test "a number the provider rejects yields the actionable error" do
    user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_reject"})

    stub(ProviderMock, :get_merchant, fn "m_reject" ->
      {:ok,
       %{
         uid: "m_reject",
         status: "pending",
         kyc_level: 0,
         compliance_status: "unverified",
         overview_url: nil
       }}
    end)

    stub(ProviderMock, :add_merchant_phone, fn "m_reject", _phone ->
      {:error,
       %Systems.Payment.Error{
         code: :api_error,
         message: "OPP API returned 400",
         details: %{status: 400, body: %{"error" => %{"parameters" => %{"phone" => "invalid"}}}}
       }}
    end)

    assert submit(user).assigns.error == t("payouts.phone.error.rejected")
  end

  test "a provider outage yields the generic try-again error" do
    user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_down"})

    stub(ProviderMock, :get_merchant, fn "m_down" ->
      {:error, %Systems.Payment.Error{code: :connection_error, message: "Failed to connect"}}
    end)

    assert submit(user).assigns.error == t("payouts.phone.error.flash")
  end

  test "a provider 500 yields the generic try-again error, not the rejected one" do
    user = Factories.insert!(:member, %{creator: false, merchant_uid: "m_500"})

    stub(ProviderMock, :get_merchant, fn "m_500" ->
      {:error,
       %Systems.Payment.Error{
         code: :api_error,
         message: "OPP API returned 503",
         details: %{status: 503, body: %{}}
       }}
    end)

    assert submit(user).assigns.error == t("payouts.phone.error.flash")
  end
end
