defmodule Systems.Paper.RISImportSessionModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Core.Repo
  alias Ecto.Multi
  alias Frameworks.Signal
  alias Systems.Paper

  schema "paper_ris_import_session" do
    field(:status, Ecto.Enum,
      values: [:activated, :succeeded, :failed, :aborted],
      default: :activated
    )

    field(:phase, Ecto.Enum,
      values: [:waiting, :parsing, :processing, :prompting, :importing],
      default: :waiting
    )

    field(:entries, {:array, :map}, default: [])
    field(:import_summary, :map, default: %{})
    field(:errors, {:array, :string}, default: [])

    field(:completed_at, :utc_datetime_usec)

    belongs_to(:paper_set, Paper.SetModel, foreign_key: :paper_set_id)
    belongs_to(:reference_file, Paper.ReferenceFileModel, foreign_key: :reference_file_id)

    timestamps()
  end

  @fields ~w(status phase entries import_summary errors completed_at)a
  @required_fields ~w(status phase)a

  def changeset(session, attrs) do
    session
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  def create_changeset(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
  end

  def update_changeset(session, attrs) do
    attrs =
      if Map.get(attrs, :status) in [:succeeded, :failed, :aborted] do
        Map.put(attrs, :completed_at, DateTime.utc_now())
      else
        attrs
      end

    changeset(session, attrs)
  end

  def advance_phase(session, phase) do
    update_changeset(session, %{phase: phase})
  end

  def mark_succeeded(session, attrs \\ %{}) do
    attrs = Map.merge(attrs, %{status: :succeeded})
    update_changeset(session, attrs)
  end

  def mark_failed(session, attrs \\ %{}) do
    attrs = Map.merge(attrs, %{status: :failed})
    update_changeset(session, attrs)
  end

  def mark_aborted(session, attrs \\ %{}) do
    attrs = Map.merge(attrs, %{status: :aborted})
    update_changeset(session, attrs)
  end

  @doc """
  Updates session status/phase and dispatches signal in a transaction
  """
  def update_with_signal(session, attrs) do
    Multi.new()
    |> Multi.update(:paper_ris_import_session, update_changeset(session, attrs))
    |> Multi.run(:dispatch_signal, fn _, %{paper_ris_import_session: session} = changes ->
      signal = determine_signal(session)
      Signal.Public.dispatch(signal, changes)
      {:ok, signal}
    end)
  end

  @doc """
  Advances phase and dispatches signal in a transaction
  """
  def advance_phase_with_signal(session, phase) do
    update_with_signal(session, %{phase: phase})
    |> Repo.commit()
  end

  def advance_phase_with_signal!(session, phase) do
    {:ok, %{paper_ris_import_session: session}} = advance_phase_with_signal(session, phase)
    session
  end

  @doc """
  Marks as succeeded and dispatches signal in a transaction
  """
  def mark_succeeded_with_signal(session, attrs \\ %{}) do
    attrs = Map.merge(attrs, %{status: :succeeded})

    update_with_signal(session, attrs)
    |> Repo.commit()
  end

  def mark_succeeded_with_signal!(session, attrs \\ %{}) do
    {:ok, %{paper_ris_import_session: session}} = mark_succeeded_with_signal(session, attrs)
    session
  end

  @doc """
  Marks as failed and dispatches signal in a transaction
  """
  def mark_failed_with_signal(session, attrs \\ %{}) do
    attrs = Map.merge(attrs, %{status: :failed})

    update_with_signal(session, attrs)
    |> Repo.commit()
  end

  def mark_failed_with_signal!(session, attrs \\ %{}) do
    {:ok, %{paper_ris_import_session: session}} = mark_failed_with_signal(session, attrs)
    session
  end

  @doc """
  Marks as aborted and dispatches signal in a transaction
  """
  def mark_aborted_with_signal(session, attrs \\ %{}) do
    attrs = Map.merge(attrs, %{status: :aborted})

    update_with_signal(session, attrs)
    |> Repo.commit()
  end

  def mark_aborted_with_signal!(session) do
    {:ok, %{paper_ris_import_session: session}} = mark_aborted_with_signal(session)
    session
  end

  defp determine_signal(%{status: status, phase: phase}) do
    case {status, phase} do
      {:activated, :waiting} -> {:paper_ris_import_session, :waiting}
      {:activated, :parsing} -> {:paper_ris_import_session, :parsing}
      {:activated, :processing} -> {:paper_ris_import_session, :processing}
      {:activated, :prompting} -> {:paper_ris_import_session, :prompting}
      {:activated, :importing} -> {:paper_ris_import_session, :importing}
      {:succeeded, _} -> {:paper_ris_import_session, :succeeded}
      {:failed, _} -> {:paper_ris_import_session, :failed}
      {:aborted, _} -> {:paper_ris_import_session, :aborted}
    end
  end

  def preload_graph(:down), do: preload_graph([:paper_set, :reference_file])
  def preload_graph(:paper_set), do: [paper_set: Paper.SetModel.preload_graph(:down)]

  def preload_graph(:reference_file),
    do: [reference_file: Paper.ReferenceFileModel.preload_graph(:down)]

  # Queries

  @doc """
  Get active import session for a reference file
  """
  def active_for_reference_file(reference_file_id) do
    from(s in __MODULE__,
      where: s.reference_file_id == ^reference_file_id,
      where: s.status == :activated,
      order_by: [desc: s.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Get active import sessions for a reference file
  """
  def active_for_reference_file_tool(reference_file_id) do
    from(s in __MODULE__,
      where: s.reference_file_id == ^reference_file_id,
      where: s.status == :activated,
      order_by: [desc: s.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Get recent sessions for a reference file (for history/debugging)
  """
  def recent_for_reference_file(reference_file_id, limit \\ 10) do
    from(s in __MODULE__,
      where: s.reference_file_id == ^reference_file_id,
      order_by: [desc: s.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Check if any import is active for a reference file
  """
  def has_active_import_for_reference_file?(reference_file_id) do
    from(s in __MODULE__,
      where: s.reference_file_id == ^reference_file_id,
      where: s.status == :activated,
      select: count(s.id)
    )
    |> Repo.one()
    |> Kernel.>(0)
  end
end
