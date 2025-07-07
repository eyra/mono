defmodule Systems.Zircon.Public do
  use Core, :public
  use Systems.Zircon.Constants
  use Gettext, backend: CoreWeb.Gettext

  require Ecto.Query
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
  def prepare_screening_tool_reference_file(tool, original_filename)
      when is_binary(original_filename) do
    prepare_screening_tool_reference_file(
      tool,
      Paper.Public.prepare_reference_file(original_filename)
    )
  end

  def prepare_screening_tool_reference_file(tool, %{} = reference_file) do
    %Zircon.Screening.ToolReferenceFileAssoc{}
    |> Zircon.Screening.ToolReferenceFileAssoc.changeset(%{})
    |> put_assoc(:tool, tool)
    |> put_assoc(:reference_file, reference_file)
  end

  @doc """
    Inserts a new paper reference file associated with the given screening tool.
  """
  def insert_screening_tool_reference_file(tool, original_filename) do
    prepare_screening_tool_reference_file(tool, original_filename)
    |> Repo.insert!()
  end

  def insert_reference_file!(tool, original_filename) do
    %{reference_file: reference_file} =
      insert_screening_tool_reference_file(tool, original_filename)

    reference_file
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
    |> Repo.transaction()
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
    |> Repo.transaction()
  end
end
