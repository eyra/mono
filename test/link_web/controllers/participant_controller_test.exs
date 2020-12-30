defmodule LinkWeb.ParticipantControllerTest do
  use LinkWeb.ConnCase

  alias Link.Factories
  alias Link.Studies

  setup %{conn: conn} do
    user = Factories.insert!(:member)
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
      assert Studies.application_status(study, user) == :applied
    end
  end

  describe "index" do
    test "deny listing participants to non-researcher", %{conn: conn} do
      # Create a new study with a different researcher
      study = Factories.insert!(:study)

      # Our currently authenticated user should not be allowed access
      conn = get(conn, Routes.participant_path(conn, :index, study))
      assert response(conn, 401)
    end

    test "lists all participants", %{conn: conn, study: study} do
      # Setup different members
      non_participant = Factories.insert!(:member)
      applied_participant = Factories.insert!(:member)
      Studies.apply_participant(study, applied_participant)
      accepted_participant = Factories.insert!(:member)
      Studies.apply_participant(study, accepted_participant)
      Studies.update_participant_status(study, accepted_participant, "entered")
      # Now verify the (non)existence of them as participants
      conn = get(conn, Routes.participant_path(conn, :index, study))
      body = html_response(conn, 200)
      refute body =~ "<td>#{non_participant.id}</td>"
      assert body =~ "<td>#{applied_participant.id}</td>"
      assert body =~ "<td>#{accepted_participant.id}</td>"
    end
  end

  describe "manage participants" do
    test "enter a study applicant", %{conn: conn, study: study} do
      participant = Factories.insert!(:member)
      Studies.apply_participant(study, participant)

      patch(conn, Routes.participant_path(conn, :update, study), %{
        "participation" => %{
          "user_id" => participant.id,
          "status" => "entered"
        }
      })

      # The member has now been registered as entered
      assert Studies.list_participants(study) == [
               %{status: :entered, user_id: participant.id}
             ]
    end
  end
end
