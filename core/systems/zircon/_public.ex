defmodule Systems.Zircon.Public do
  use Core, :public
  use Systems.Zircon.Constants
  use Gettext, backend: CoreWeb.Gettext

  require Ecto.Query
  require Logger
  import Ecto.Query, warn: false
  import Ecto.Changeset, only: [put_assoc: 3]
  import Systems.Zircon.Queries

  alias Ecto.Multi
  alias Core.Repo
  alias Core.Authentication
  alias Frameworks.Signal

  alias Systems.Annotation
  alias Systems.Ontology
  alias Systems.Paper
  alias Systems.Zircon

  # Screening Tool

  def get_screening_tool!(id, preload \\ []) do
    screening_tool_query()
    |> Repo.get!(id)
    |> Repo.preload(preload)
  end

  def get_screening_tool_by_reference_file!(
        %Paper.ReferenceFileModel{} = reference_file,
        preload \\ []
      ) do
    screening_tool_query(reference_file)
    |> Repo.one!()
    |> Repo.preload(preload)
  end

  @doc """
    Creates a screening tool without saving.
  """
  def prepare_screening_tool(attrs, auth_node \\ auth_module().prepare_node(), user) do
    %Zircon.Screening.ToolModel{}
    |> Zircon.Screening.ToolModel.changeset(attrs)
    |> put_assoc(:annotations, obtain_screening_tool_annotations(user))
    |> put_assoc(:auth_node, auth_node)
  end

  def obtain_screening_tool_annotations(user) do
    entity = Authentication.obtain_entity!(user)

    @criteria_dimensions
    |> Enum.map(&Ontology.Public.obtain_concept!(&1, entity))
    |> Enum.map(fn dimension ->
      obtain_screening_tool_annotation!(dimension, entity)
    end)
  end

  def obtain_screening_tool_annotation!(dimension, entity) do
    case obtain_screening_tool_annotation(dimension, entity) do
      {:ok, annotation} -> annotation
      {:error, _} -> raise "Failed to obtain screening tool annotation"
    end
  end

  def obtain_screening_tool_annotation(dimension, entity) do
    %Annotation.Pattern.Parameter{
      statement: dgettext("eyra-zircon", "statement.unspecified", dimension: dimension.phrase),
      dimension: dimension,
      entity: entity
    }
    |> Annotation.Pattern.obtain()
  end

  # ReferenceFile

  @doc """
    Creates an association between the given screening tool and the paper reference file at
    the given url without saving.
  """
  def prepare_screening_tool_reference_file_assoc(tool, %{} = reference_file) do
    %Zircon.Screening.ToolReferenceFileAssoc{}
    |> Zircon.Screening.ToolReferenceFileAssoc.changeset(%{})
    |> put_assoc(:tool, tool)
    |> put_assoc(:reference_file, reference_file)
  end

  @doc """
    Inserts a new paper reference file associated with the given screening tool.
  """
  def insert_reference_file!(tool, original_filename) do
    insert_reference_file(tool, original_filename)
    |> case do
      {:ok, tool} ->
        tool

      _ ->
        raise "Failed to insert screening tool reference file"
    end
  end

  def insert_reference_file!(tool, original_filename, url) when is_binary(url) do
    insert_reference_file(tool, original_filename, url)
    |> case do
      {:ok, tool} ->
        tool

      _ ->
        raise "Failed to insert screening tool reference file"
    end
  end

  def insert_reference_file(tool, original_filename) do
    Multi.new()
    |> Multi.put(:zircon_screening_tool, tool)
    |> Multi.insert(:paper_reference_file, Paper.Public.prepare_reference_file(original_filename))
    |> Multi.insert(:zircon_screening_tool_reference_file_assoc, fn %{
                                                                      zircon_screening_tool: tool,
                                                                      paper_reference_file:
                                                                        reference_file
                                                                    } ->
      prepare_screening_tool_reference_file_assoc(tool, reference_file)
    end)
    |> Repo.commit()
    |> case do
      {:ok, %{zircon_screening_tool_reference_file_assoc: %{reference_file: reference_file}}} ->
        {:ok, reference_file}

      error ->
        error
    end
  end

  def insert_reference_file(tool, original_filename, url) when is_binary(url) do
    Multi.new()
    |> Multi.put(:zircon_screening_tool, tool)
    |> Multi.insert(
      :paper_reference_file,
      Paper.Public.prepare_reference_file(original_filename, url)
    )
    |> Multi.insert(:zircon_screening_tool_reference_file_assoc, fn %{
                                                                      zircon_screening_tool: tool,
                                                                      paper_reference_file:
                                                                        reference_file
                                                                    } ->
      prepare_screening_tool_reference_file_assoc(tool, reference_file)
    end)
    |> Repo.commit()
    |> case do
      {:ok, %{zircon_screening_tool_reference_file_assoc: %{reference_file: reference_file}}} ->
        {:ok, reference_file}

      error ->
        error
    end
  end

  def list_screening_tool_reference_files(tool) do
    screening_tool_reference_file_query(tool)
    |> Repo.all()
    |> Repo.preload(Zircon.Screening.ToolReferenceFileAssoc.preload_graph(:down))
  end

  def list_reference_files(tool) do
    list_screening_tool_reference_files(tool)
    |> Enum.map(& &1.reference_file)
  end

  @doc """
  Gets the latest uploaded reference file for a tool.
  Returns a map with :file (the reference file) and :file_info (filename and url).
  Returns nil if no uploaded file exists.
  """
  def get_latest_uploaded_reference_file(tool) do
    reference_files = list_reference_files(tool)

    # Find the most recently uploaded file that hasn't been processed yet
    # Status :uploaded means file is fresh and available for import
    latest_unprocessed_file =
      reference_files
      |> Enum.filter(fn ref_file -> ref_file.status == :uploaded end)
      |> Enum.sort_by(& &1.inserted_at, {:desc, NaiveDateTime})
      |> List.first()

    case latest_unprocessed_file do
      nil ->
        nil

      reference_file ->
        # Preload the file association and extract info
        reference_file = reference_file |> Repo.preload(:file)
        filename = reference_file.file && reference_file.file.name
        url = reference_file.file && reference_file.file.ref

        %{
          file: reference_file,
          file_info: %{filename: filename, url: url}
        }
    end
  end

  @doc """
  Gets all uploaded reference files for a tool.
  Returns a list of reference file IDs that have :uploaded status.
  """
  def get_uploaded_reference_file_ids(tool) do
    reference_files = list_reference_files(tool)

    reference_files
    |> Enum.filter(fn ref_file -> ref_file.status == :uploaded end)
    |> Enum.map(& &1.id)
  end

  @doc """
  Cleans up all reference files for a tool before uploading a new file.
  This aborts any active imports and archives all uploaded files.
  """
  def cleanup_reference_files_for_new_upload!(tool) do
    reference_files = list_reference_files(tool)

    # Get all reference file IDs
    all_ref_file_ids = Enum.map(reference_files, & &1.id)

    # Abort any active imports for all reference files
    Systems.Paper.Public.abort_active_imports_for_reference_files!(all_ref_file_ids)

    # Get IDs of uploaded files to archive
    uploaded_file_ids =
      reference_files
      |> Enum.filter(fn ref_file -> ref_file.status == :uploaded end)
      |> Enum.map(& &1.id)

    # Archive all uploaded files
    if length(uploaded_file_ids) > 0 do
      Systems.Paper.Public.archive_reference_files!(uploaded_file_ids)
    end
  end

  @doc """
  Aborts any active import sessions for the tool and archives all uploaded reference files.
  This clears the file selector and stops any ongoing imports.
  """
  def abort_active_imports!(tool) do
    reference_files = list_reference_files(tool)

    Enum.each(reference_files, fn ref_file ->
      # Check if this file has an active import session
      abort_session_if_active(ref_file)

      # Archive any uploaded reference file to clear it from file selector
      # This handles both files with active sessions and files waiting to be imported
      if ref_file.status == :uploaded do
        Paper.Public.archive_reference_file!(ref_file.id)
      end
    end)
  end

  defp abort_session_if_active(ref_file) do
    if Paper.Public.has_active_import_for_reference_file?(ref_file.id) do
      active_session = Paper.Public.get_active_import_session_for_reference_file(ref_file.id)

      if active_session do
        # Abort the import session
        Paper.Public.abort_import_session!(active_session)
      end
    end
  end

  @doc """
  Aborts an import by cancelling the session and archiving its reference file.
  This completely cleans up the import, removing it from the file selector.
  """
  def abort_import!(session) do
    # Build the Multi with both operations and signals
    Multi.new()
    |> Multi.update(
      :paper_ris_import_session,
      Paper.RISImportSessionModel.update_changeset(session, %{status: :aborted})
    )
    |> Multi.update(
      :paper_reference_file,
      Paper.ReferenceFileModel.changeset(
        Paper.Public.get_reference_file!(session.reference_file_id),
        %{status: :archived}
      )
    )
    # Synchronous signals for cascading DB operations (handled by Zircon.Switch)
    |> Signal.Public.multi_dispatch({:paper_ris_import_session, :aborted},
      name: :dispatch_abort_signal
    )
    |> Signal.Public.multi_dispatch({:paper_reference_file, :updated},
      name: :dispatch_archive_signal
    )
    # Use Repo.commit to dispatch collected Observatory updates
    |> Repo.commit()
    |> case do
      {:ok, _changes} ->
        :ok

      {:error, operation, changeset, _} ->
        raise "Failed to abort import at #{operation}: #{inspect(changeset)}"
    end
  end

  def list_papers(tool) do
    list_reference_files(tool)
    |> Enum.reduce([], fn %{papers: papers}, acc ->
      acc ++ papers
    end)
    |> Enum.uniq_by(& &1.id)
  end

  def insert_screening_tool_criterion(
        %Zircon.Screening.ToolModel{} = tool,
        %Ontology.ConceptModel{} = dimension,
        user
      ) do
    entity = Authentication.obtain_entity!(user)

    Multi.new()
    |> Multi.run(:validate_criterion_does_not_exist, fn _, _ ->
      %{annotations: annotations} =
        tool |> Repo.preload(annotations: Annotation.Model.preload_graph(:down))

      if Annotation.Public.member?(annotations, dimension) do
        {:error, false}
      else
        {:ok, true}
      end
    end)
    |> Multi.run(:annotation, fn _, _ ->
      %Annotation.Pattern.Parameter{
        statement: dgettext("eyra-zircon", "statement.unspecified", dimension: dimension.phrase),
        dimension: dimension,
        entity: entity
      }
      |> Annotation.Pattern.obtain()
    end)
    |> Multi.insert(:zircon_screening_tool_annotation_assoc, fn %{annotation: annotation} ->
      %Zircon.Screening.ToolAnnotationAssoc{}
      |> Zircon.Screening.ToolAnnotationAssoc.changeset(%{})
      |> put_assoc(:tool, tool)
      |> put_assoc(:annotation, annotation)
    end)
    |> Signal.Public.multi_dispatch({:zircon_screening_tool_annotation_assoc, :inserted})
    |> Repo.commit()
  end

  def delete_screening_tool_criterion(
        %Zircon.Screening.ToolModel{} = tool,
        %Annotation.Model{} = criterion
      ) do
    Multi.new()
    |> Multi.put(:zircon_screening_tool, tool)
    |> Multi.delete_all(
      :screening_tool_annotation_assoc,
      screening_tool_annotation_assoc_query(criterion)
    )
    |> Multi.run(:orphan_delete_criterion, fn _, _ ->
      if Repo.orphan?(criterion, ignore: [Annotation.Assoc]) do
        Repo.delete(criterion)
      else
        {:ok, "Criterion is not orphaned, skipping deletion"}
      end
    end)
    |> Signal.Public.multi_dispatch({:zircon_screening_tool_annotation_assoc, :deleted})
    |> Repo.commit()
  end

  # Screening Session

  def invalidate_screening_sessions(tool) do
    Multi.new()
    |> Multi.update_all(:zircon_screening_sessions, screening_session_query(tool),
      set: [invalidated_at: DateTime.utc_now()]
    )
    |> Signal.Public.multi_dispatch({:zircon_screening_sessions, :invalidated})
    |> Repo.commit()
  end

  def prepare_screening_session(identifier, agent_state, tool, user) do
    %Zircon.Screening.SessionModel{}
    |> Zircon.Screening.SessionModel.changeset(%{identifier: identifier, agent_state: agent_state})
    |> put_assoc(:tool, tool)
    |> put_assoc(:user, user)
  end

  def obtain_screening_session!(tool, user) do
    {:ok, session} = obtain_screening_session(tool, user)
    session
  end

  def obtain_screening_session(tool, user) do
    case get_screening_session(tool, user) do
      nil ->
        session = start_screening_session!(tool, user)
        {:ok, session}

      session ->
        {:ok, session}
    end
  end

  def get_screening_session(tool, user) do
    screening_session_query(tool, user) |> Repo.one()
  end

  def start_screening_session!(tool, user) do
    case start_screening_session(tool, user) do
      {:ok, session} ->
        session

      {:error, _} ->
        raise "Failed to start screening agent session"
    end
  end

  def start_screening_session(tool, user) do
    identifier = Systems.Zircon.Sqids.encode!([tool.id, user.id])

    # For now we just have one configurable screening agent module, but in the future we may have multiple agents running in parallel
    Multi.new()
    |> Multi.run(:zircon_screening_agent_state, fn _, _ ->
      papers = list_papers(tool)

      %{annotations: criteria} =
        tool |> Repo.preload(annotations: Annotation.Model.preload_graph(:down))

      Zircon.Config.screening_agent_module().start(identifier, papers, criteria)
    end)
    |> Multi.insert(:zircon_screening_session, fn %{zircon_screening_agent_state: agent_state} ->
      prepare_screening_session(identifier, agent_state, tool, user)
    end)
    |> Repo.commit()
    |> case do
      {:ok, %{zircon_screening_session: screening_session}} ->
        {:ok, screening_session}

      {:error, _} ->
        {:error, "Failed to start screening agent session"}
    end
  end

  def update_screening_session(session, agent_state) do
    session
    |> Zircon.Screening.SessionModel.changeset(%{agent_state: agent_state})
    |> Repo.update()
  end
end
