defmodule Systems.Assignment.GdprFormTest do
  use Mica.DataCase
  use Gettext, backend: MicaWeb.Gettext

  alias Systems.Assignment
  alias Systems.Consent

  setup do
    participant = Factories.insert!(:member)
    assignment = Assignment.Factories.create_assignment_with_consent()
    %{assignment: assignment, participant: participant}
  end

  describe "switching consent off" do
    test "without the confirmation modal keeps the signed text and its signatures", %{
      assignment: %{consent_agreement: agreement} = assignment,
      participant: participant
    } do
      default_text = dgettext("eyra-consent", "default.consent.text")

      revision =
        agreement
        |> Consent.Public.latest_revision()
        |> Ecto.Changeset.change(source: default_text)
        |> Repo.update!()

      {:ok, _} = Consent.Public.create_signature(revision, participant)

      {:noreply, _socket} =
        Assignment.GdprForm.handle_event(
          "update",
          %{status: :off},
          Assignment.Factories.gdpr_socket(assignment)
        )

      assignment = Assignment.Public.get!(assignment.id, Assignment.Model.preload_graph(:down))
      assert_off_and_kept(assignment, agreement, revision, participant)
    end

    test "with the confirmation modal keeps the signed text and its signatures", %{
      assignment: %{consent_agreement: agreement} = assignment,
      participant: participant
    } do
      revision = Consent.Public.latest_revision(agreement)
      {:ok, _} = Consent.Public.create_signature(revision, participant)

      assignment = Assignment.Factories.switch_consent(assignment, :off)

      assert_off_and_kept(assignment, agreement, revision, participant)
    end
  end

  describe "switching consent on again" do
    test "reuses the same agreement with its texts and signatures", %{
      assignment: %{consent_agreement: agreement} = assignment,
      participant: participant
    } do
      revision = Consent.Public.latest_revision(agreement)
      {:ok, _} = Consent.Public.create_signature(revision, participant)

      assignment =
        assignment
        |> Assignment.Factories.switch_consent(:off)
        |> Assignment.Factories.switch_consent(:on)

      assert assignment.consent_agreement_id == agreement.id
      assert status(assignment) == :on
      assert %{id: revision_id} = Consent.Public.latest_revision(assignment.consent_agreement)
      assert revision_id == revision.id
      assert Consent.Public.get_signature(assignment.consent_agreement, participant)
    end
  end

  defp assert_off_and_kept(assignment, agreement, revision, participant) do
    assert status(assignment) == :off
    assert assignment.consent_agreement_id == agreement.id

    kept = Consent.Public.get_revision!(revision.id)
    assert kept.source == revision.source
    assert Consent.Public.get_signature(kept, participant)
  end

  defp status(assignment) do
    %{assigns: %{status: status}} =
      assignment
      |> Assignment.Factories.gdpr_socket()
      |> Assignment.GdprForm.update_status()

    status
  end
end
