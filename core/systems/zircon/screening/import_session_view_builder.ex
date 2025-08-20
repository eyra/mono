defmodule Systems.Zircon.Screening.ImportSessionViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Paper.RISEntry

  # Status-based view_model functions

  def view_model(%{status: :activated} = session, _assigns) do
    handle_activated_status(session)
    |> add_filename(session)
  end

  def view_model(%{status: :failed} = session, _assigns) do
    handle_failed_status(session)
    |> add_filename(session)
  end

  def view_model(%{status: :succeeded} = session, _assigns) do
    handle_succeeded_status(session)
    |> add_filename(session)
  end

  def view_model(%{status: :aborted} = session, _assigns) do
    handle_aborted_status(session)
    |> add_filename(session)
  end

  # Phase-specific handlers for activated status

  defp handle_activated_status(%{phase: :waiting} = _session) do
    %{
      stack: [
        {:processing_status,
         %{
           message: dgettext("eyra-zircon", "import_session.phase.waiting"),
           show_spinner: true
         }}
      ]
    }
  end

  defp handle_activated_status(%{phase: :parsing} = _session) do
    %{
      stack: [
        {:processing_status,
         %{
           message: dgettext("eyra-zircon", "import_session.phase.parsing"),
           show_spinner: true
         }}
      ]
    }
  end

  defp handle_activated_status(%{phase: :processing} = _session) do
    %{
      stack: [
        {:processing_status,
         %{
           message: dgettext("eyra-zircon", "import_session.phase.processing"),
           show_spinner: true
         }}
      ]
    }
  end

  defp handle_activated_status(
         %{phase: :prompting, reference_file: %{file: %{name: filename}}} = session
       ) do
    # Parse entries to show results
    ris_entries_data = Map.get(session, :entries) || []

    # Convert all entries to RISEntry structs
    ris_entries = ris_entries_data |> Enum.map(&RISEntry.from_map/1)

    # Extract new papers
    new_papers = ris_entries |> Enum.filter(&(&1.status == "new"))

    # Extract error entries (these have line numbers)
    entry_errors = RISEntry.process_entry_errors(Map.get(session, :entries) || [])

    # No buttons in prompting phase - they're handled by ImportView
    # Put content blocks directly in stack
    %{
      stack: create_content(new_papers, entry_errors, filename),
      has_errors: length(entry_errors) > 0
    }
  end

  defp handle_activated_status(%{phase: :importing} = _session) do
    %{
      stack: [
        {:processing_status,
         %{
           message: dgettext("eyra-zircon", "import_session.phase.importing"),
           show_spinner: true
         }}
      ]
    }
  end

  # Fallback for unexpected phases
  defp handle_activated_status(_session) do
    %{
      stack: [
        {:processing_status,
         %{
           message: dgettext("eyra-zircon", "import_session.phase.unknown"),
           show_spinner: true
         }}
      ]
    }
  end

  defp handle_failed_status(session) do
    # File-level failure - show single error message
    error_message =
      session
      |> Map.get(:errors, [])
      |> List.last()
      |> Kernel.||(dgettext("eyra-zircon", "import_session.status.failed.default"))

    %{
      stack: [
        {:failed, %{message: error_message}}
      ]
    }
  end

  defp handle_succeeded_status(_session) do
    %{
      stack: [
        {:succeeded,
         %{
           message: dgettext("eyra-zircon", "import_session.status.succeeded")
         }}
      ]
    }
  end

  defp handle_aborted_status(_session) do
    %{
      stack: [
        {:aborted,
         %{
           message: dgettext("eyra-zircon", "import_session.status.aborted")
         }}
      ]
    }
  end

  defp create_content(new_papers, errors, filename) do
    has_new_papers = new_papers |> Enum.count() > 0
    has_errors = length(errors) > 0

    empty =
      {:prompting_empty,
       %{
         description:
           dgettext("eyra-zircon", "import_session.phase.prompting.empty", filename: filename)
       }}

    new_papers_block =
      {:prompting_new_papers,
       %{
         title: dgettext("eyra-zircon", "import_session.prompting.new_papers_title"),
         count: length(new_papers)
       }}

    errors_block =
      {:prompting_errors,
       %{
         title: dgettext("eyra-zircon", "import_session.prompting.errors_title"),
         count: length(errors)
       }}

    case {has_new_papers, has_errors} do
      {true, true} ->
        # Show errors on top, new papers below
        [errors_block, new_papers_block]

      {false, true} ->
        # Only errors
        [errors_block]

      {true, false} ->
        # Only new papers
        [new_papers_block]

      {false, false} ->
        # Nothing found
        [empty]
    end
  end

  defp add_filename(view_model, %{reference_file: %{file: %{name: filename}}}) do
    Map.put(view_model, :filename, filename)
  end

  defp add_filename(view_model, _session) do
    # If no reference file or file name, don't add filename
    view_model
  end
end
