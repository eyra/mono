defmodule Systems.Consent.PublicTest do
  use Core.DataCase
  alias Core.Authorization
  alias Ecto.Multi

  alias Systems.Consent

  test "list/0 returns all created agreements" do
    {:ok, %{id: id}} =
      Authorization.prepare_node()
      |> Consent.Public.create_agreement()

    assert [%Systems.Consent.AgreementModel{id: ^id}] = Consent.Public.list_agreements()
  end

  test "list/0 returns all created agreements with revisions" do
    {:ok, _} =
      Multi.new()
      |> Multi.insert(:agreement, Consent.Public.prepare_agreement(Authorization.prepare_node()))
      |> Multi.insert(:revision1, fn %{agreement: agreement} ->
        Consent.Public.prepare_revision("revision1", agreement)
      end)
      |> Multi.insert(:revision2, fn %{agreement: agreement} ->
        Consent.Public.prepare_revision("revision2", agreement)
      end)
      |> Repo.transaction()

    assert [%Systems.Consent.AgreementModel{
      revisions: [
        %Systems.Consent.RevisionModel{
          source: "revision1",
        },
        %Systems.Consent.RevisionModel{
          source: "revision2",
        }
      ]
    }] = Consent.Public.list_agreements([:revisions])
  end

  test "list/0 returns all created agreements with revisions and signatures" do
    %{id: user_a_id} = user_a = Factories.insert!(:member)
    %{id: user_b_id} = user_b = Factories.insert!(:member)
    %{id: user_c_id} = user_c = Factories.insert!(:member)

    {:ok, _} =
      Multi.new()
      |> Multi.insert(:agreement, Consent.Public.prepare_agreement(Authorization.prepare_node()))
      |> Multi.insert(:revision1, fn %{agreement: agreement} ->
        Consent.Public.prepare_revision("revision1", agreement)
      end)
      |> Multi.insert(:signatureA1, fn %{revision1: revision1} ->
        Consent.Public.prepare_signature(revision1, user_a)
      end)
      |> Multi.insert(:signatureB1, fn %{revision1: revision1} ->
        Consent.Public.prepare_signature(revision1, user_b)
      end)
      |> Multi.insert(:revision2, fn %{agreement: agreement} ->
        Consent.Public.prepare_revision("revision2", agreement)
      end)
      |> Multi.insert(:signatureA2, fn %{revision2: revision2} ->
        Consent.Public.prepare_signature(revision2, user_a)
      end)
      |> Multi.insert(:signatureB2, fn %{revision2: revision2} ->
        Consent.Public.prepare_signature(revision2, user_b)
      end)
      |> Multi.insert(:signatureC2, fn %{revision2: revision2} ->
        Consent.Public.prepare_signature(revision2, user_c)
      end)
      |> Repo.transaction()

    assert [%Systems.Consent.AgreementModel{
      revisions: [
        %Systems.Consent.RevisionModel{
          source: "revision1",
          signatures: [
            %Systems.Consent.SignatureModel{user_id: ^user_a_id},
            %Systems.Consent.SignatureModel{user_id: ^user_b_id},
          ]
        },
        %Systems.Consent.RevisionModel{
          source: "revision2",
          signatures: [
            %Systems.Consent.SignatureModel{user_id: ^user_a_id},
            %Systems.Consent.SignatureModel{user_id: ^user_b_id},
            %Systems.Consent.SignatureModel{user_id: ^user_c_id}
          ]
        }
      ]
    }] = Consent.Public.list_agreements([revisions: [:signatures]])
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

   test "latest_unlocked_revision_safe/2 returns new revision in empty agreement" do
    agreement = Factories.insert!(:consent_agreement)

    assert %Systems.Consent.RevisionModel{
     source: "<div>Beschrijf hier de consent voorwaarden</div>",
     signatures: [],
   } = Consent.Public.latest_unlocked_revision_safe(agreement, [:signatures])
  end

  test "latest_unlocked_revision_safe/2 returns latest revision" do
    agreement = Factories.insert!(:consent_agreement)
    _revision = Factories.insert!(:consent_revision, %{agreement: agreement, source: "source"})

    assert %Systems.Consent.RevisionModel{
     source: "source",
     signatures: [],
   } = Consent.Public.latest_unlocked_revision_safe(agreement, [:signatures])
  end

  test "latest_unlocked_revision_safe/2 returns new revision on top of locked revision" do
    user = Factories.insert!(:member)

     agreement = Factories.insert!(:consent_agreement)
     revision_1 = Factories.insert!(:consent_revision, %{agreement: agreement, source: "source"})
     _signature = Factories.insert!(:consent_signature, %{revision: revision_1, user: user})

     assert %Systems.Consent.RevisionModel{
      id: revision_2_id,
      source: "source",
      signatures: [],
    } = Consent.Public.latest_unlocked_revision_safe(agreement, [:signatures])

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
 end
