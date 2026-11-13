defmodule Systems.Consent.PublicTest do
  use Mica.DataCase
  alias Ecto.Multi
  alias Systems.Consent

  test "list/0 returns all created agreements" do
    {:ok, %{id: id}} =
      Mica.Authorization.prepare_node()
      |> Consent.Public.create_agreement()

    assert [%Systems.Consent.AgreementModel{id: ^id}] = Consent.Public.list_agreements()
  end

  test "list/0 returns all created agreements with revisions" do
    {:ok, _} =
      Multi.new()
      |> Multi.insert(
        :agreement,
        Consent.Public.prepare_agreement(Mica.Authorization.prepare_node())
      )
      |> Multi.insert(:revision2, fn %{agreement: agreement} ->
        Consent.Public.prepare_revision(agreement, "revision2")
      end)
      |> Multi.insert(:revision3, fn %{agreement: agreement} ->
        Consent.Public.prepare_revision(agreement, "revision3")
      end)
      |> Repo.commit()

    assert [
             %Systems.Consent.AgreementModel{
               revisions: [
                 %Systems.Consent.RevisionModel{
                   source: _
                 },
                 %Systems.Consent.RevisionModel{
                   source: "revision2"
                 },
                 %Systems.Consent.RevisionModel{
                   source: "revision3"
                 }
               ]
             }
           ] = Consent.Public.list_agreements([:revisions])
  end

  test "list/0 returns all created agreements with revisions and signatures" do
    %{id: user_a_id} = user_a = Factories.insert!(:member)
    %{id: user_b_id} = user_b = Factories.insert!(:member)
    %{id: user_c_id} = user_c = Factories.insert!(:member)

    {:ok, _} =
      Multi.new()
      |> Multi.insert(
        :agreement,
        Consent.Public.prepare_agreement(Mica.Authorization.prepare_node())
      )
      |> Multi.insert(:revision2, fn %{agreement: agreement} ->
        Consent.Public.prepare_revision(agreement, "revision2")
      end)
      |> Multi.insert(:signatureA1, fn %{revision2: revision2} ->
        Consent.Public.prepare_signature(revision2, user_a)
      end)
      |> Multi.insert(:signatureB1, fn %{revision2: revision2} ->
        Consent.Public.prepare_signature(revision2, user_b)
      end)
      |> Multi.insert(:revision3, fn %{agreement: agreement} ->
        Consent.Public.prepare_revision(agreement, "revision3")
      end)
      |> Multi.insert(:signatureA2, fn %{revision3: revision3} ->
        Consent.Public.prepare_signature(revision3, user_a)
      end)
      |> Multi.insert(:signatureB2, fn %{revision3: revision3} ->
        Consent.Public.prepare_signature(revision3, user_b)
      end)
      |> Multi.insert(:signatureC2, fn %{revision3: revision3} ->
        Consent.Public.prepare_signature(revision3, user_c)
      end)
      |> Repo.commit()

    assert [
             %Systems.Consent.AgreementModel{
               revisions: [
                 %Systems.Consent.RevisionModel{
                   source: _source,
                   signatures: []
                 },
                 %Systems.Consent.RevisionModel{
                   source: "revision2",
                   signatures: [
                     %Systems.Consent.SignatureModel{user_id: ^user_a_id},
                     %Systems.Consent.SignatureModel{user_id: ^user_b_id}
                   ]
                 },
                 %Systems.Consent.RevisionModel{
                   source: "revision3",
                   signatures: [
                     %Systems.Consent.SignatureModel{user_id: ^user_a_id},
                     %Systems.Consent.SignatureModel{user_id: ^user_b_id},
                     %Systems.Consent.SignatureModel{user_id: ^user_c_id}
                   ]
                 }
               ]
             }
           ] = Consent.Public.list_agreements(revisions: [:signatures])
  end

  test "latest_revision/2 returns nil" do
    agreement = Factories.insert!(:consent_agreement)
    assert Consent.Public.latest_revision(agreement) == nil
  end

  test "latest_revision/2 returns latest revision " do
    %{id: id} = agreement = Factories.insert!(:consent_agreement)
    %{id: _revision_1_id} = Factories.insert!(:consent_revision, %{agreement: agreement})
    %{id: revision_2_id} = Factories.insert!(:consent_revision, %{agreement: agreement})

    assert %Systems.Consent.RevisionModel{
             id: ^revision_2_id,
             source: nil,
             agreement: %Systems.Consent.AgreementModel{id: ^id}
           } = Consent.Public.latest_revision(agreement, [:agreement])
  end

  test "latest_unlocked_revision/2 returns nil" do
    user = Factories.insert!(:member)

    agreement = Factories.insert!(:consent_agreement)
    revision_1 = Factories.insert!(:consent_revision, %{agreement: agreement})
    _signature = Factories.insert!(:consent_signature, %{revision: revision_1, user: user})

    assert Consent.Public.latest_unlocked_revision(agreement, [:agreement]) == nil
  end

  test "bump_revision_if_needed!/1 returns first revision" do
    agreement = Factories.insert!(:consent_agreement)

    assert %Systems.Consent.RevisionModel{
             source: "<div>Add terms and conditions that participants need to consent to.</div>"
           } = Consent.Public.bump_revision_if_needed!(agreement)
  end

  test "bump_revision_if_needed!/1 returns latest revision" do
    agreement = Factories.insert!(:consent_agreement)
    %{id: id} = Factories.insert!(:consent_revision, %{agreement: agreement, source: "source"})

    assert %Systems.Consent.RevisionModel{
             id: ^id,
             source: "source"
           } = Consent.Public.bump_revision_if_needed!(agreement)
  end

  test "bump_revision_if_needed!/1 returns new revision on top of locked revision" do
    user = Factories.insert!(:member)

    agreement = Factories.insert!(:consent_agreement)
    revision_1 = Factories.insert!(:consent_revision, %{agreement: agreement, source: "source"})
    _signature = Factories.insert!(:consent_signature, %{revision: revision_1, user: user})

    assert %Systems.Consent.RevisionModel{
             id: revision_2_id,
             source: "source"
           } = Consent.Public.bump_revision_if_needed!(agreement)

    assert revision_1.id != revision_2_id
  end

  test "create_signature/2 succeeds" do
    user = Factories.insert!(:member)

    agreement = Factories.insert!(:consent_agreement)
    revision = Factories.insert!(:consent_revision, %{agreement: agreement})

    assert {:ok, _} = Consent.Public.create_signature(revision, user)
  end

  test "create_signature/2 fails when signature already exists" do
    user = Factories.insert!(:member)

    agreement = Factories.insert!(:consent_agreement)
    revision = Factories.insert!(:consent_revision, %{agreement: agreement})
    _signature = Factories.insert!(:consent_signature, %{revision: revision, user: user})

    assert_raise Ecto.ConstraintError, fn -> Consent.Public.create_signature(revision, user) end
  end

  test "has_signature/2 true" do
    user = Factories.insert!(:member)

    agreement = Factories.insert!(:consent_agreement)
    revision = Factories.insert!(:consent_revision, %{agreement: agreement})
    _signature = Factories.insert!(:consent_signature, %{revision: revision, user: user})

    assert Consent.Public.has_signature(revision, user)
  end

  test "has_signature/2 false" do
    user_a = Factories.insert!(:member)
    user_b = Factories.insert!(:member)

    agreement = Factories.insert!(:consent_agreement)
    revision = Factories.insert!(:consent_revision, %{agreement: agreement})
    _signature = Factories.insert!(:consent_signature, %{revision: revision, user: user_a})

    assert not Consent.Public.has_signature(revision, user_b)
  end

  test "get_agreement!/2 preloads revisions oldest first, also when an older row is stored last" do
    agreement = Factories.insert!(:consent_agreement)

    %{id: revision_1_id} =
      revision_1 = Factories.insert!(:consent_revision, %{agreement: agreement})

    %{id: revision_2_id} = Factories.insert!(:consent_revision, %{agreement: agreement})
    move_to_end_of_table(revision_1)

    assert %{revisions: [%{id: ^revision_1_id}, %{id: ^revision_2_id}]} =
             Consent.Public.get_agreement!(agreement.id, [:revisions])
  end

  test "get_revision!/2 preloads signatures oldest first, also when an older row is stored last" do
    # The later signature gets the user with the lower id, so the order of the
    # (revision_id, user_id) index differs from the signature order too.
    user_b = Factories.insert!(:member)
    user_a = Factories.insert!(:member)
    revision = Factories.insert!(:consent_revision)
    signature_a = Factories.insert!(:consent_signature, %{revision: revision, user: user_a})
    signature_b = Factories.insert!(:consent_signature, %{revision: revision, user: user_b})
    move_to_end_of_table(signature_a)

    signature_a_id = signature_a.id
    signature_b_id = signature_b.id

    assert %{signatures: [%{id: ^signature_a_id}, %{id: ^signature_b_id}]} =
             Consent.Public.get_revision!(revision.id, [:signatures])
  end

  test "get_signature/2 returns the signature on the latest signed revision, also when an older row is stored last" do
    user = Factories.insert!(:member)
    agreement = Factories.insert!(:consent_agreement)
    revision_1 = Factories.insert!(:consent_revision, %{agreement: agreement})

    %{id: revision_2_id} =
      revision_2 = Factories.insert!(:consent_revision, %{agreement: agreement})

    signature_1 = Factories.insert!(:consent_signature, %{revision: revision_1, user: user})
    _signature_2 = Factories.insert!(:consent_signature, %{revision: revision_2, user: user})
    move_to_end_of_table(revision_1)
    move_to_end_of_table(signature_1)

    assert %{revision_id: ^revision_2_id} = Consent.Public.get_signature(agreement, user)
  end

  # Deletes the row and inserts it again, unchanged, in one statement. Postgres
  # stores it after the rows that were inserted later, with new index entries,
  # so a query without ORDER BY returns it after them.
  defp move_to_end_of_table(%schema{id: id}) do
    table = schema.__schema__(:source)

    Repo.query!(
      "WITH moved AS (DELETE FROM #{table} WHERE id = $1 RETURNING *) " <>
        "INSERT INTO #{table} SELECT * FROM moved",
      [id]
    )
  end
end
