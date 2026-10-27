defmodule Systems.Fund.PayInRequestFormTest do
  @moduledoc """
  The pay-in form on the assignment's Participants tab, after the payment
  provider refuses the first pay-in (UC-OPP-01.A1).
  """

  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Mox
  import Ecto.Query, only: [from: 2]

  alias Core.Factories
  alias Core.Repo
  alias Systems.Assignment
  alias Systems.Payment.ProviderMock
  alias Systems.Project

  setup :set_mox_global
  setup :verify_on_exit!

  @add_button "[data-testid='pay-add-participants-button']"
  @confirm_form "form[phx-submit='confirm']"
  @request %{
    "aim_of_study" => "Ten-participant test with a valid aim-of-study text.",
    "subject_reward" => "5.00",
    "subject_count" => "10"
  }

  setup %{conn: conn} do
    ensure_currency_ledger(:EUR)

    researcher = Factories.insert!(:creator, %{merchant_uid: "m_pay_in_form"})
    {:ok, conn: conn, user: _} = login(researcher, %{conn: conn})

    {:ok, %{project: project}} = Project.Assembly.create("Project", researcher, :empty)

    {:ok, %{project_item: %{assignment_id: assignment_id}}} =
      Project.Assembly.create_item(:questionnaire, "Study", project.root, researcher)

    backdate_info(assignment_id)

    stub(ProviderMock, :get_merchant, fn _uid ->
      {:ok,
       %{uid: "m_pay_in_form", status: "active", kyc_level: 100, compliance_status: "verified"}}
    end)

    %{conn: conn, assignment_id: assignment_id}
  end

  test "a researcher can retry a pay-in after the provider refused it",
       %{conn: conn, assignment_id: assignment_id} do
    ProviderMock
    |> expect(:create_transaction, fn _request -> {:error, :provider_unavailable} end)
    |> expect(:create_transaction, fn _request ->
      {:ok, %{uid: "tx_retry", payment_url: "/payment/local/tx_retry", status: "created"}}
    end)

    {:ok, view, _html} =
      conn
      |> put_connect_params(%{"viewport" => %{"width" => 1280, "height" => 800}})
      |> live(~p"/assignment/#{assignment_id}/content")

    view |> element(@add_button) |> render_click()
    view |> form(@confirm_form, pay_in_request: @request) |> render_submit()

    # The form tells the participants view, which tells the page to hide the
    # modal: two messages to the LiveView process. `render/1` waits for the
    # first; `has_element?/2` is queued behind the second.
    render(view)
    refute has_element?(view, @confirm_form)

    view |> element(@add_button) |> render_click()

    assert {:error, {:redirect, %{to: "/payment/local/tx_retry"}}} =
             view |> form(@confirm_form, pay_in_request: @request) |> render_submit()
  end

  # `updated_at` has second precision. Backdating it makes the first
  # pay-in's save land in a later second, so a stale assignment always
  # trips the update guard.
  defp backdate_info(assignment_id) do
    %{info_id: info_id} = Repo.get!(Assignment.Model, assignment_id)

    an_hour_ago =
      NaiveDateTime.utc_now() |> NaiveDateTime.add(-3600) |> NaiveDateTime.truncate(:second)

    from(i in Assignment.InfoModel, where: i.id == ^info_id)
    |> Repo.update_all(set: [updated_at: an_hour_ago])
  end

  defp ensure_currency_ledger(currency) do
    case Systems.Fund.CurrencyLedgerModel.get_by_currency(currency) do
      nil -> Factories.insert!(:currency_ledger, %{currency: currency})
      existing -> existing
    end
  end
end
