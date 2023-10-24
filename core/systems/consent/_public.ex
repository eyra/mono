defmodule Systems.Consent.Public do
  import CoreWeb.Gettext
  import Ecto.Query

  alias Ecto.Multi
  alias Core.Repo
  alias Frameworks.Signal

  alias Systems.{
    Consent
  }


  def create_agreement(auth_node) do
    prepare_agreement(auth_node)
    |> Repo.insert()
  end

  def prepare_agreement(auth_node) do
    %Consent.AgreementModel{}
    |> Consent.AgreementModel.changeset()
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
  end

  def create_revision(source, agreement) do
    prepare_revision(source, agreement)
    |> Repo.insert()
  end

  def prepare_revision(source, agreement) when is_binary(source) do
    %Consent.RevisionModel{}
    |> Consent.RevisionModel.changeset(%{source: source})
    |> Ecto.Changeset.put_assoc(:agreement, agreement)
  end

  def create_signature(revision, user) do
    prepare_signature(revision, user)
    |> Repo.insert()
  end

  def prepare_signature(revision, user) do
    %Consent.SignatureModel{}
    |> Consent.SignatureModel.changeset()
    |> Ecto.Changeset.put_assoc(:revision, revision)
    |> Ecto.Changeset.put_assoc(:user, user)
  end

  def get_agreement!(id, preload \\ []) do
    Repo.get!(Consent.AgreementModel, id) |> Repo.preload(preload)
  end

  def get_revision!(id, preload \\ []) do
    Repo.get!(Consent.RevisionModel, id) |> Repo.preload(preload)
  end

  def has_signature(revision, user) do
    get_signature(revision, user) != nil
  end

  def get_signature(%Consent.RevisionModel{id: revision_id}, %Core.Accounts.User{id: user_id}) do
    from(s in Consent.SignatureModel,
      where: s.user_id == ^user_id,
      where: s.revision_id == ^revision_id
    )
    |> Repo.all()
    |> List.first()
  end

  def list_agreements(preload \\ []) do
    from(a in Consent.AgreementModel,
      order_by: {:desc, :inserted_at},
      preload: ^preload,
      limit: 1
    )
    |> Repo.all()
  end

  def latest_unlocked_revision_safe(agreement, preload \\ []) do
    if revision = latest_unlocked_revision(agreement, preload) do
      revision
    else
      source =
        if revision = latest_revision(agreement, preload) do
          revision.source
        else
          dgettext("eyra-consent", "default.consent.text")
        end

      create_revision(source, agreement)
    end

    query_unlocked_revisions(agreement, preload)
    |> Repo.all()
    |> List.first()
  end

  def latest_unlocked_revision(agreement, preload \\ []) do
    query_unlocked_revisions(agreement, preload)
    |> Repo.all()
    |> List.first()
  end

  def query_unlocked_revisions(agreement, preload \\ []) do
    from(revision in query_revisions(agreement, preload),
      where: revision.id not in subquery(
        from(signature in Consent.SignatureModel,
          select: signature.revision_id
        )
      )
    )
  end

  def latest_revision(agreement, preload \\ []) do
    query_revisions(agreement, preload)
    |> Repo.all()
    |> List.first()
  end

  def query_revisions(agreement, preload \\ [])
  def query_revisions(%Consent.AgreementModel{id: agreement_id}, preload) do
    query_revisions(agreement_id, preload)
  end
  def query_revisions(agreement_id, preload) when is_integer(agreement_id) do
    from(revision in Consent.RevisionModel,
      where: revision.agreement_id == ^agreement_id,
      order_by: {:desc, :id},
      preload: ^preload
    )
  end

  def update_revision(%Ecto.Changeset{data: %Consent.RevisionModel{id: id, updated_at: updated_at}} = changeset) do
    Multi.new()
    |> Multi.run(:validate_timestamp, fn _, _ ->
      %{updated_at: stored_updated_at} = Consent.Public.get_revision!(id)
      if stored_updated_at == updated_at do
        {:ok, :valid}
      else
        {:error, "Revision out of sync"}
      end
    end)
    |> Multi.update(:consent_revision, changeset)
    |> Signal.Public.multi_dispatch({:consent_revision, :updated})
    |> Repo.transaction()
  end
end

defimpl Core.Persister, for: Systems.Consent.RevisionModel do
  def save(_revision, changeset) do
    case Systems.Consent.Public.update_revision(changeset) do
      {:ok, %{consent_revision: revision}} -> {:ok, revision}
      _ -> {:error, changeset}
    end
  end
end
