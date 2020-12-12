defmodule LinkWeb.ParticipantControllerTest do
  use LinkWeb.ConnCase

  alias Link.Studies

  setup %{conn: conn} do
    user = user_fixture()
    {:ok, study} = Studies.create_study(%{title: "Test", description: "Testing"}, user)
    conn = Pow.Plug.assign_current_user(conn, user, otp_app: :link_web)

    {:ok, conn: conn, user: user, study: study}
  end

  describe "show apply screen for a member" do
    test "renders application screen", %{conn: conn, study: study} do
      conn = get(conn, Routes.participant_path(conn, :new, study))
      assert html_response(conn, 200) =~ "Apply to participate"
    end
  end

  describe "apply as a participant" do
    test "redirects to study when data is valid", %{conn: conn, user: user, study: study} do
      conn = post(conn, Routes.participant_path(conn, :create, study))

      assert redirected_to(conn) == Routes.study_path(conn, :show, study.id)

      # The user has now been registered as applied
      assert Studies.applied?(study, user)
    end
  end

  # describe "index" do
  #   test "lists all participants", %{conn: conn} do
  #     conn = get(conn, Routes.participant_path(conn, :index))
  #     assert html_response(conn, 200) =~ "Listing Participants"
  #   end
  # end

  # describe "create participant" do
  #   test "redirects to show when data is valid", %{conn: conn} do
  #     conn = post(conn, Routes.participant_path(conn, :create), participant: @create_attrs)

  #     assert %{id: id} = redirected_params(conn)
  #     assert redirected_to(conn) == Routes.participant_path(conn, :show, id)

  #     conn = get(conn, Routes.participant_path(conn, :show, id))
  #     assert html_response(conn, 200) =~ "Show Participant"
  #   end

  #   test "renders errors when data is invalid", %{conn: conn} do
  #     conn = post(conn, Routes.participant_path(conn, :create), participant: @invalid_attrs)
  #     assert html_response(conn, 200) =~ "New Participant"
  #   end
  # end

  # describe "edit participant" do
  #   setup [:create_participant]

  #   test "renders form for editing chosen participant", %{conn: conn, participant: participant} do
  #     conn = get(conn, Routes.participant_path(conn, :edit, participant))
  #     assert html_response(conn, 200) =~ "Edit Participant"
  #   end
  # end

  # describe "update participant" do
  #   setup [:create_participant]

  #   test "redirects when data is valid", %{conn: conn, participant: participant} do
  #     conn =
  #       put(conn, Routes.participant_path(conn, :update, participant), participant: @update_attrs)

  #     assert redirected_to(conn) == Routes.participant_path(conn, :show, participant)

  #     conn = get(conn, Routes.participant_path(conn, :show, participant))
  #     assert html_response(conn, 200)
  #   end

  #   test "renders errors when data is invalid", %{conn: conn, participant: participant} do
  #     conn =
  #       put(conn, Routes.participant_path(conn, :update, participant), participant: @invalid_attrs)

  #     assert html_response(conn, 200) =~ "Edit Participant"
  #   end
  # end

  # describe "delete participant" do
  #   setup [:create_participant]

  #   test "deletes chosen participant", %{conn: conn, participant: participant} do
  #     conn = delete(conn, Routes.participant_path(conn, :delete, participant))
  #     assert redirected_to(conn) == Routes.participant_path(conn, :index)

  #     assert_error_sent 404, fn ->
  #       get(conn, Routes.participant_path(conn, :show, participant))
  #     end
  #   end
  # end
end
