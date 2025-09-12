defmodule Systems.Consent.Public do
  use Core, :public
  use Gettext, backend: CoreWeb.Gettext
  import Ecto.Query
  import Systems.Consent.Queries

  alias Ecto.Multi
  alias Core.Repo
  alias Frameworks.Signal

  alias Systems.Account
  alias Systems.Consent

  def create_agreement(auth_node) do
    prepare_agreement(auth_node)
    |> Repo.insert()
  end

  def prepare_agreement(auth_node) do
    %Consent.AgreementModel{}
    |> Consent.AgreementModel.changeset()
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Ecto.Changeset.put_assoc(:revisions, [prepare_revision(nil)])
  end

  def bump_revision_if_needed(agreement_id) when is_integer(agreement_id) do
    agreement_id
    |> get_agreement!()
    |> bump_revision_if_needed()
  end

  def bump_revision_if_needed(agreement) do
    Multi.new()
    |> Multi.run(:revision, fn _, _ ->
      case latest_revision(agreement, [:signatures]) do
        nil -> create_revision(agreement, nil)
        %{source: source, signatures: [_ | _]} -> create_revision(agreement, source)
        revision -> {:ok, revision}
      end
    end)
    |> Repo.commit()
  end

  def bump_revision_if_needed!(agreement) do
    case bump_revision_if_needed(agreement) do
      {:ok, %{revision: revision}} -> revision
      _ -> nil
    end
  end

  def create_revision(agreement, source) do
    prepare_revision(agreement, source)
    |> Repo.insert()
  end

  def prepare_revision(nil) do
    dgettext("eyra-consent", "default.consent.text")
    |> prepare_revision()
  end

  def prepare_revision(source) when is_binary(source) do
    %Consent.RevisionModel{}
    |> Consent.RevisionModel.changeset(%{source: source})
  end

  def prepare_revision(agreement, source) do
    prepare_revision(source)
    |> Ecto.Changeset.put_assoc(:agreement, agreement)
  end

  def create_signature(revision, user) do
    Multi.new()
    |> Multi.insert(:consent_signature, prepare_signature(revision, user))
    |> Signal.Public.multi_dispatch({:consent_signature, :created})
    |> Repo.commit()
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

  def has_signature(context, user_ref) do
    get_signature(context, user_ref) != nil
  end

  def get_signature(%Consent.AgreementModel{id: agreement_id}, user_ref) do
    user_id = Account.User.user_id(user_ref)

    from(s in Consent.SignatureModel,
      join: r in Consent.RevisionModel,
      on: r.id == s.revision_id,
      where: s.user_id == ^user_id,
      where: r.agreement_id == ^agreement_id,
      preload: [:revision]
    )
    |> Repo.all()
    |> List.last()
  end

  def get_signature(%Consent.RevisionModel{id: revision_id}, user_ref) do
    user_id = Account.User.user_id(user_ref)

    from(s in Consent.SignatureModel,
      where: s.user_id == ^user_id,
      where: s.revision_id == ^revision_id
    )
    |> Repo.all()
    |> List.last()
  end

  def list_agreements(preload \\ []) do
    from(a in Consent.AgreementModel,
      order_by: {:desc, :inserted_at},
      preload: ^preload,
      limit: 1
    )
    |> Repo.all()
  end

  def latest_unlocked_revision(agreement, preload \\ []) do
    query_unlocked_revisions(agreement, preload)
    |> Repo.all()
    |> List.first()
  end

  def query_unlocked_revisions(agreement, preload \\ []) do
    from(revision in query_revisions(agreement, preload),
      where:
        revision.id not in subquery(
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

  def update_revision(
        %Ecto.Changeset{data: %Consent.RevisionModel{id: id, updated_at: updated_at}} = changeset
      ) do
    Multi.new()
    |> Multi.run(:validate, fn _, _ ->
      %{updated_at: stored_updated_at, signatures: signatures} =
        Consent.Public.get_revision!(id, [:signatures])

      cond do
        stored_updated_at != updated_at ->
          {:error, :out_of_sync}

        not Enum.empty?(signatures) ->
          {:error, :locked}

        true ->
          {:ok, :valid}
      end
    end)
    |> Multi.update(:consent_revision, changeset)
    |> Signal.Public.multi_dispatch({:consent_revision, :updated})
    |> Repo.commit()
  end

  def list_signatures(%Consent.AgreementModel{} = consent_agreement) do
    signature_query(consent_agreement)
    |> Repo.all()
  end
end

defimpl Core.Persister, for: Systems.Consent.RevisionModel do
  use Gettext, backend: CoreWeb.Gettext

  def save(_revision, changeset) do
    case Systems.Consent.Public.update_revision(changeset) do
      {:ok, %{consent_revision: revision}} ->
        {:ok, revision}

      {:error, _, _, _} = error ->
        {:error, changeset |> handle_error(error)}
    end
  end

  defp handle_error(changeset, {:error, :validate, :locked, _}) do
    Systems.Consent.Public.bump_revision_if_needed!(changeset.data.agreement_id)

    changeset
    |> Ecto.Changeset.add_error(:locked, dgettext("eyra-consent", "locked.error.message"))
  end

  defp handle_error(changeset, {:error, :validate, :out_of_sync, _}) do
    changeset
    |> Ecto.Changeset.add_error(
      :out_of_sync,
      dgettext("eyra-consent", "out_of_sync.error.message")
    )
  end

  defp handle_error(changeset, _), do: changeset
end
