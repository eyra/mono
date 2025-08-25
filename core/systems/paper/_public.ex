defmodule Systems.Paper.Public do
  use Gettext, backend: CoreWeb.Gettext

  import Systems.Paper.Queries
  require Ecto.Query
  import Ecto.Query, warn: false
  import Ecto.Changeset, only: [put_assoc: 3]
  require Logger

  alias Core.Repo
  alias Ecto.Changeset
  alias Ecto.Multi
  alias Frameworks.Signal
  alias Systems.Content
  alias Systems.Paper

  # Reference File

  def get_reference_file!(id, preload \\ []) do
    reference_file_query()
    |> Repo.get!(id)
    |> Repo.preload(preload)
  end

  def update!(%Paper.ReferenceFileModel{file: file} = reference_file, ref) do
    reference_file
    |> Paper.ReferenceFileModel.changeset(%{})
    |> put_assoc(:file, file |> Content.FileModel.changeset(%{ref: ref}))
    |> Repo.update!()
  end

  def mark_as_failed!(
        %Paper.ReferenceFileModel{} = reference_file,
        %Paper.RISError{message: message} = _error
      ) do
    Multi.new()
    |> Multi.update(:paper_reference_file, update_reference_file_status(reference_file, :failed))
    |> Multi.insert(
      :paper_reference_file_error,
      prepare_reference_file_error(reference_file, message)
    )
    |> Signal.Public.multi_dispatch({:paper_reference_file, :updated})
    |> Repo.commit()
  end

  @doc """
    Creates a ReferenceFile without saving.
  """
  def prepare_reference_file(original_filename) when is_binary(original_filename) do
    prepare_reference_file(Content.Public.prepare_file(original_filename, nil))
  end

  def prepare_reference_file(%{} = content_file) do
    %Paper.ReferenceFileModel{}
    |> Paper.ReferenceFileModel.changeset(%{})
    |> put_assoc(:file, content_file)
  end

  def prepare_reference_file(original_filename, url)
      when is_binary(original_filename) and is_binary(url) do
    prepare_reference_file(Content.Public.prepare_file(original_filename, url))
  end

  def update_reference_file_status(reference_file, status) do
    Paper.ReferenceFileModel.changeset(reference_file, %{status: status})
  end

  @doc """
  Archives a reference file within a Multi transaction.
  Adds the archive operation and signal dispatch to the given Multi.
  """
  def multi_archive_reference_file(multi, reference_file_id) when is_integer(reference_file_id) do
    reference_file = Repo.get!(Paper.ReferenceFileModel, reference_file_id)

    multi
    |> Multi.update(
      :paper_reference_file,
      Paper.ReferenceFileModel.changeset(reference_file, %{status: :archived})
    )
    |> Signal.Public.multi_dispatch({:paper_reference_file, :updated},
      name: :dispatch_archive_signal
    )
  end

  def archive_reference_file!(reference_file_id) when is_integer(reference_file_id) do
    Multi.new()
    |> multi_archive_reference_file(reference_file_id)
    |> Repo.commit()
    |> case do
      {:ok, %{paper_reference_file: updated_reference_file}} ->
        updated_reference_file

      {:error, _operation, changeset, _changes} ->
        raise Ecto.InvalidChangesetError, changeset: changeset
    end
  end

  @doc """
  Aborts active import sessions for multiple reference files.
  Returns the number of sessions aborted.
  """
  def abort_active_imports_for_reference_files!(reference_file_ids)
      when is_list(reference_file_ids) do
    aborted_count =
      reference_file_ids
      |> Enum.filter(&has_active_import_for_reference_file?/1)
      |> Enum.map(fn ref_file_id ->
        Logger.info("Aborting active import session for reference file #{ref_file_id}")

        active_session = get_active_import_session_for_reference_file(ref_file_id)

        if active_session do
          abort_import_session!(active_session)
          1
        else
          0
        end
      end)
      |> Enum.sum()

    Logger.info("Aborted #{aborted_count} active import sessions")
    aborted_count
  end

  @doc """
  Archives multiple reference files by their IDs.
  This is used to clean up stale uploaded files.
  Returns the number of files archived.
  """

  def archive_reference_files([]) do
    Logger.debug("No files to archive")
    0
  end

  def archive_reference_files(file_ids) when is_list(file_ids) do
    Logger.info("Archiving #{length(file_ids)} reference files: #{inspect(file_ids)}")

    multi =
      Multi.new()
      |> Multi.update_all(
        :archive_files,
        # Update all reference files to archived status in one query
        from(rf in Paper.ReferenceFileModel,
          where: rf.id in ^file_ids
        ),
        set: [status: :archived, updated_at: NaiveDateTime.utc_now()]
      )

    file_ids
    |> Enum.reduce(multi, fn file_id, acc_multi ->
      # Add signal dispatch for each archived file
      # We need to reload each file as a struct before dispatching
      multi_add_reference_file_reload_and_dispatch(acc_multi, file_id)
    end)
    |> Repo.commit()
  end

  @doc """
  Archives multiple reference files by their IDs.
  This is used to clean up stale uploaded files.
  Returns the number of files archived.
  """

  def archive_reference_files!(file_ids) when is_list(file_ids) do
    case archive_reference_files(file_ids) do
      {:ok, %{archive_files: {count, _}}} ->
        Logger.info("Successfully archived #{count} reference files")
        count

      {:error, operation, error, _} ->
        Logger.error("Failed to archive reference files at #{operation}: #{inspect(error)}")
        raise "Failed to archive reference files: #{inspect(error)}"
    end
  end

  def prepare_import_session!(reference_file, paper_set) do
    prepare_import_session(reference_file, paper_set)
    |> case do
      {:ok, session} ->
        session

      {:error, error} ->
        raise "Failed to start importing reference file: #{inspect(error)}"
    end
  end

  def prepare_import_session(
        %Paper.ReferenceFileModel{} = reference_file,
        %Paper.SetModel{} = paper_set
      ) do
    # Create session, enqueue job, and dispatch signal atomically
    Multi.new()
    |> Multi.insert(
      :paper_ris_import_session,
      Paper.RISImportSessionModel.create_changeset(%{
        status: :activated,
        phase: :waiting
      })
      |> put_assoc(:reference_file, reference_file)
      |> put_assoc(:paper_set, paper_set)
    )
    |> Multi.run(:job, fn _repo, %{paper_ris_import_session: session} ->
      %{"session_id" => session.id}
      |> Paper.RISImportPrepareJob.new()
      |> Oban.insert()
    end)
    |> Signal.Public.multi_dispatch({:paper_ris_import_session, :waiting})
    |> Repo.commit()
    |> case do
      {:ok, %{paper_ris_import_session: session}} ->
        {:ok, session}

      {:error, _operation, changeset, _changes} ->
        {:error, changeset}
    end
  end

  def get_active_import_session_for_reference_file(reference_file_id)
      when is_integer(reference_file_id) do
    Paper.RISImportSessionModel.active_for_reference_file_tool(reference_file_id)
    |> List.first()
  end

  def has_active_import_for_reference_file?(reference_file_id)
      when is_integer(reference_file_id) do
    Paper.RISImportSessionModel.has_active_import_for_reference_file?(reference_file_id)
  end

  def get_import_session!(session_id, preload \\ []) do
    Repo.get!(Paper.RISImportSessionModel, session_id)
    |> Repo.preload(preload)
  end

  @doc """
  Aborts an import session within a Multi transaction.
  Adds the abort operation and signal dispatch to the given Multi.
  """
  def multi_abort_import_session(multi, session) do
    multi
    |> Multi.update(
      :paper_ris_import_session,
      Paper.RISImportSessionModel.update_changeset(session, %{status: :aborted})
    )
    |> Signal.Public.multi_dispatch({:paper_ris_import_session, :aborted},
      name: :dispatch_abort_signal
    )
  end

  def abort_import_session!(session) do
    Paper.RISImportSessionModel.mark_aborted_with_signal!(session)
  end

  def commit_import_session!(session) do
    # First, transition to importing phase with signal
    {:ok, %{paper_ris_import_session: updated_session}} =
      session
      |> Paper.RISImportSessionModel.advance_phase_with_signal(:importing)

    # Then enqueue async job for the actual import work
    %{"session_id" => updated_session.id}
    |> Paper.RISImportCommitJob.new()
    |> Oban.insert!()

    # Return the updated session in importing phase
    updated_session
  end

  def get_recent_import_sessions_for_reference_file(reference_file_id, limit \\ 10) do
    Paper.RISImportSessionModel.recent_for_reference_file(reference_file_id, limit)
  end

  def paper_ids_from_reference_file(%Paper.ReferenceFileModel{} = reference_file) do
    paper_query(reference_file)
    |> select([paper: p], p.id)
    |> Repo.all()
  end

  # Reference File Error

  @doc """
    Creates a ReferenceFileErrorModel without saving.
  """
  def prepare_reference_file_error(reference_file, error) do
    truncated_error = String.slice(error, 0, 255)

    %Paper.ReferenceFileErrorModel{}
    |> Paper.ReferenceFileErrorModel.changeset(%{error: truncated_error})
    |> put_assoc(:reference_file, reference_file)
  end

  # File Paper

  @doc """
    Creates a ReferenceFilePaperAssoc without saving.
  """
  def prepare_file_paper(reference_file) do
    %Paper.ReferenceFilePaperAssoc{}
    |> Paper.ReferenceFilePaperAssoc.changeset(%{})
    |> put_assoc(:reference_file, reference_file)
  end

  def finalize_file_paper(file_paper, %{paper: paper}) do
    finalize_file_paper(file_paper, paper)
  end

  def finalize_file_paper(file_paper, paper) do
    put_assoc(file_paper, :paper, paper)
  end

  # Paper Set

  def obtain_paper_set!(category, identifier) when is_atom(category) and is_integer(identifier) do
    case get_paper_set(category, identifier) do
      nil -> insert_paper_set!(category, identifier)
      set -> set
    end
  end

  def get_paper_set!(id, preload \\ []) when is_integer(id) do
    from(Paper.SetModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_paper_set(category, identifier) when is_atom(category) and is_integer(identifier) do
    paper_set_query(category, identifier)
    |> Repo.one()
  end

  def insert_paper_set!(category, identifier) when is_atom(category) and is_integer(identifier) do
    prepare_paper_set(category, identifier)
    |> Repo.insert!()
  end

  def prepare_paper_set(category, identifier) when is_atom(category) and is_integer(identifier) do
    %Paper.SetModel{}
    |> Paper.SetModel.changeset(%{category: category, identifier: identifier})
  end

  def remove_paper_from_set!(paper_set_id, paper_id)
      when is_integer(paper_set_id) and is_integer(paper_id) do
    Multi.new()
    |> Multi.delete_all(
      :delete_association,
      from(assoc in Paper.SetAssoc,
        where: assoc.set_id == ^paper_set_id and assoc.paper_id == ^paper_id
      )
    )
    |> Multi.run(:paper_set, fn _repo, _changes ->
      {:ok, get_paper_set!(paper_set_id, [:papers])}
    end)
    |> Signal.Public.multi_dispatch({:paper_set, :updated})
    |> Repo.commit()
    |> case do
      {:ok, _changes} ->
        :ok

      {:error, _operation, error, _changes} ->
        raise "Failed to remove paper from set: #{inspect(error)}"
    end
  end

  # Paper

  @doc """
    Creates a PaperModel without saving.
  """
  # credo:disable-for-next-line
  def prepare_paper(
        doi,
        title,
        subtitle,
        year,
        date,
        abbreviated_journal,
        authors,
        abstract,
        keywords
      ) do
    %Paper.Model{}
    |> Paper.Model.changeset(%{
      doi: doi,
      title: title,
      subtitle: subtitle,
      year: year,
      date: date,
      abbreviated_journal: abbreviated_journal,
      authors: authors,
      abstract: abstract,
      keywords: keywords
    })
  end

  def get!(id, preloads \\ []) do
    Repo.get!(Paper.Model, id)
    |> Repo.preload(preloads)
  end

  # Error

  def prepare_error({:unsupported_type_of_reference, type_of_reference}) do
    dgettext("eyra-zircon", "unsupported_type_of_reference", type: type_of_reference)
  end

  # RIS

  def prepare_ris(raw) do
    %Paper.RISModel{}
    |> Paper.RISModel.changeset(%{raw: raw})
  end

  def finalize_ris(ris, %{paper: paper}) do
    finalize_ris(ris, paper)
  end

  def finalize_ris(ris, paper) do
    Changeset.put_assoc(ris, :paper, paper)
  end

  # Helper function to reload a reference file and dispatch signal within a Multi
  defp multi_add_reference_file_reload_and_dispatch(multi, file_id) do
    reload_key = String.to_atom("reload_file_#{file_id}")
    dispatch_key = String.to_atom("dispatch_archive_signal_#{file_id}")

    multi
    |> Multi.run(reload_key, fn _repo, _changes ->
      {:ok, Repo.get!(Paper.ReferenceFileModel, file_id)}
    end)
    |> Multi.run(dispatch_key, fn _repo, changes ->
      reloaded_file = Map.get(changes, reload_key)

      Signal.Public.dispatch(
        {:paper_reference_file, :updated},
        %{paper_reference_file: reloaded_file}
      )

      {:ok, :dispatched}
    end)
  end
end
