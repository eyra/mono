defmodule Systems.Zircon.Screening.ImportViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Core.Repo
  alias Systems.Paper
  alias Systems.Zircon

  # Threshold for showing progress - only show for 20+ items
  @progress_threshold 20

  def view_model(%{id: tool_id} = tool, assigns) do
    # Extract title from different possible locations
    title =
      case assigns do
        %{"title" => title} -> title
        %{session: %{"title" => title}} -> title
        _ -> dgettext("eyra-zircon", "import_view.title")
      end

    paper_set =
      Paper.Public.obtain_paper_set!(:zircon_screening_tool, tool_id) |> Repo.preload([:papers])

    paper_count = paper_set.papers |> Enum.count()
    import_status = determine_import_status(tool)

    button_config = build_button_config(import_status)

    paper_set_view =
      LiveNest.Element.prepare_live_view(:paper_set, Zircon.Screening.PaperSetView,
        paper_set_id: paper_set.id
      )

    import_session_view = build_import_session_view(import_status.active_session, nil)

    # Check if we should show the file selector
    # Show when: no session, or during processing/prompting phases
    show_file_selector =
      import_status.active_session == nil ||
        session_has_errors_or_processing?(import_status.active_session)

    # Get file info - either from active session or latest uploaded file
    active_file_info =
      case import_status.active_session do
        nil ->
          # No active session, check for uploaded files
          get_latest_uploaded_file_info(tool)

        session ->
          # Has active session, use session file
          get_active_file_info(session)
      end

    # Determine if we should show import buttons (only when no active session AND has filename)
    show_import_buttons = import_status.active_session == nil && active_file_info.filename != nil

    import_section_stack =
      build_import_section_stack(
        import_session_view,
        show_file_selector,
        show_import_buttons,
        button_config
      )

    stack = [
      {:header,
       %{
         title: title,
         paper_count: paper_count
       }},
      {:import_section,
       %{
         stack: import_section_stack
       }}
    ]

    # Only add content block if there are papers
    stack =
      if paper_count > 0 do
        stack ++
          [
            {:content,
             %{
               paper_set_view: paper_set_view
             }}
          ]
      else
        stack
      end

    vm = %{
      stack: stack,
      active_filename: active_file_info.filename,
      active_file_url: active_file_info.url,
      modal_title: dgettext("eyra-zircon", "import_view.modal.importing_details"),
      modal_warnings_title: dgettext("eyra-zircon", "import_session.prompting.errors_title"),
      modal_new_papers_title:
        dgettext("eyra-zircon", "import_session.prompting.new_papers_title"),
      modal_duplicates_title: dgettext("eyra-zircon", "import_session.prompting.duplicates_title")
    }

    # Add prompting_session_id if we have a prompting summary
    case import_session_view do
      %{type: :prompting_summary, session: session} ->
        Map.put(vm, :prompting_session_id, session.id)

      _ ->
        vm
    end
  end

  defp determine_import_status(tool) do
    # Get all reference files for this tool and check if any have active imports
    reference_files = Zircon.Public.list_reference_files(tool)

    active_import =
      reference_files
      |> Enum.map(fn ref_file ->
        Paper.Public.get_active_import_session_for_reference_file(ref_file.id)
      end)
      |> Enum.reject(&is_nil/1)
      |> List.first()

    import_status =
      case active_import do
        nil ->
          :idle

        %{status: :activated, phase: phase} ->
          # For active sessions, use the phase to determine the current state
          phase

        %{status: status} ->
          # For completed sessions, use the status
          status
      end

    # Only consider sessions with :activated status as truly "active"
    # Completed/failed sessions shouldn't be treated as active
    active_session =
      case active_import do
        %{status: :activated} ->
          active_import

        _ ->
          nil
      end

    %{
      status: import_status,
      active_session: active_session
    }
  end

  defp build_button_config(import_status) do
    case import_status.status do
      status when status in [:parsing, :processing, :importing] ->
        # Import is running - show built-in spinner
        %{
          face: %{
            type: :primary,
            label: dgettext("eyra-zircon", "import_view.button.prepare_import"),
            loading: true
          },
          enabled: true
        }

      :waiting ->
        # Waiting for job to start - show built-in spinner
        %{
          face: %{
            type: :primary,
            label: dgettext("eyra-zircon", "import_view.button.prepare_import"),
            loading: true
          },
          enabled: true
        }

      _ ->
        # Idle, completed, failed, or aborted - normal button
        %{
          face: %{
            type: :primary,
            label: dgettext("eyra-zircon", "import_view.button.prepare_import"),
            loading: false
          },
          enabled: true
        }
    end
  end

  defp build_import_session_view(active_session, _batch_progress) do
    case active_session do
      %{status: :activated, phase: :prompting} = session ->
        # For prompting phase, return session data for summary display
        %{type: :prompting_summary, session: session}

      %{status: :activated, phase: phase} = session
      when phase in [:waiting, :parsing, :processing, :importing] ->
        # For processing phases, show a simple processing status (not embedded view)
        %{type: :processing_status, session: session, phase: phase}

      _ ->
        # No active session or session is completed/failed/aborted - don't show anything
        nil
    end
  end

  defp get_active_file_info(active_session) do
    case active_session do
      %{reference_file_id: reference_file_id} when not is_nil(reference_file_id) ->
        # Fetch the reference file with file preloaded
        reference_file = Paper.Public.get_reference_file!(reference_file_id, [:file])
        filename = get_filename_from_reference_file(reference_file)
        url = get_url_from_reference_file(reference_file)
        %{filename: filename, url: url}

      _ ->
        # No active session or no reference file
        %{filename: nil, url: nil}
    end
  end

  defp get_latest_uploaded_file_info(tool) do
    case Zircon.Public.get_latest_uploaded_reference_file(tool) do
      nil ->
        # No uploaded files available - file selector should show placeholder
        %{filename: nil, url: nil}

      %{file_info: file_info} ->
        # Return the file info
        file_info
    end
  end

  defp get_filename_from_reference_file(%{file: %{name: name}}) when not is_nil(name), do: name
  defp get_filename_from_reference_file(_), do: nil

  defp get_url_from_reference_file(%{file: %{ref: ref}}) when not is_nil(ref), do: ref
  defp get_url_from_reference_file(_), do: nil

  defp session_has_errors_or_processing?(nil), do: false

  defp session_has_errors_or_processing?(%{status: :activated, phase: phase})
       when phase in [:waiting, :parsing, :processing, :importing] do
    # Show file selector during all processing phases including importing
    # This allows users to cancel or replace the file even during import
    true
  end

  defp session_has_errors_or_processing?(%{status: :activated, phase: :prompting}) do
    # Always show file selector during prompting phase so users can replace the file
    true
  end

  defp session_has_errors_or_processing?(_), do: false

  defp build_import_section_stack(
         import_session_view,
         show_file_selector,
         show_import_buttons,
         button_config
       ) do
    file_selector_block =
      {:import_file_selector,
       %{
         placeholder: dgettext("eyra-zircon", "import_view.file_import.placeholder"),
         select_button: dgettext("eyra-zircon", "import_view.file_import.select_button"),
         replace_button: dgettext("eyra-zircon", "import_view.file_import.replace_button")
       }}

    import_buttons_block =
      {:import_buttons,
       %{
         import_button_face: button_config.face,
         import_button_enabled: button_config.enabled
       }}

    stack = []

    # Check if we have a prompting summary to show
    case import_session_view do
      %{type: :prompting_summary, session: session} ->
        # Build prompting summary block instead of full session view
        # Show file selector if there are errors or still processing
        stack =
          if show_file_selector do
            stack ++ [file_selector_block]
          else
            stack
          end

        prompting_block = build_prompting_summary_block(session)
        stack ++ [prompting_block]

      nil ->
        # Add file selector if needed (no session OR processing phases OR errors)
        stack =
          if show_file_selector do
            stack ++ [file_selector_block]
          else
            stack
          end

        # Add import buttons only when no active session
        if show_import_buttons do
          stack ++ [import_buttons_block]
        else
          stack
        end

      %{type: :processing_status, session: session, phase: phase} ->
        # Show processing status for active phases (not embedded view)
        stack =
          if show_file_selector do
            stack ++ [file_selector_block]
          else
            stack
          end

        processing_block = build_processing_status_block(session, phase)
        # Only add the block if it's not nil (small operations don't show status)
        if processing_block do
          stack ++ [processing_block]
        else
          stack
        end

      _ ->
        # This should never happen now
        stack
    end
  end

  defp build_processing_status_block(session, phase) do
    # Check if we should show the block at all
    if should_show_processing_status?(session, phase) do
      message = get_processing_message(session, phase)
      progress = get_processing_progress(session, phase)

      {:processing_status,
       %{
         message: message,
         show_spinner: true,
         progress: progress,
         buttons: []
       }}
    else
      # Don't show processing status for small operations
      nil
    end
  end

  defp should_show_processing_status?(session, :processing) do
    # For processing phase, check progress.total_references
    # This is set after parsing completes
    if session.progress && Map.get(session.progress, "total_references") do
      Map.get(session.progress, "total_references", 0) >= @progress_threshold
    else
      # No progress data yet, default to showing (shouldn't happen after our fix)
      true
    end
  end

  defp should_show_processing_status?(session, :importing) do
    # For importing phase, count new papers in entries
    entries = Map.get(session, :entries, [])

    new_paper_count =
      entries
      |> Enum.count(fn entry ->
        case entry do
          %{"status" => "new"} -> true
          %{status: "new"} -> true
          _ -> false
        end
      end)

    new_paper_count >= @progress_threshold
  end

  defp should_show_processing_status?(_session, _phase) do
    # Always show for parsing and waiting phases
    true
  end

  defp get_processing_message(_session, :waiting) do
    dgettext("eyra-zircon", "import_view.processing.waiting")
  end

  defp get_processing_message(_session, :parsing) do
    dgettext("eyra-zircon", "import_view.processing.parsing")
  end

  defp get_processing_message(_session, :processing) do
    dgettext("eyra-zircon", "import_view.processing.processing")
  end

  defp get_processing_message(_session, :importing) do
    # Simple message without counts
    dgettext("eyra-zircon", "import_view.processing.importing")
  end

  defp get_processing_progress(session, :processing) do
    # Calculate progress percentage for processing phase
    # We already checked threshold in should_show_processing_status?
    if session.progress && Map.get(session.progress, "total_references") do
      current = Map.get(session.progress, "current_reference", 0)
      total = Map.get(session.progress, "total_references", 1)

      # Calculate percentage (0-100)
      round(current / total * 100)
    else
      nil
    end
  end

  defp get_processing_progress(session, :importing) do
    # Calculate progress percentage for importing phase
    # We already checked threshold in should_show_processing_status?
    if session.progress && Map.get(session.progress, "total_papers") do
      processed = Map.get(session.progress, "papers_processed", 0)
      total = Map.get(session.progress, "total_papers", 1)

      # Calculate percentage (0-100)
      round(processed / total * 100)
    else
      nil
    end
  end

  defp get_processing_progress(_session, :parsing) do
    # Show progress spinner at 0% for parsing phase
    0
  end

  defp get_processing_progress(_session, _phase) do
    # For other phases, no specific progress
    nil
  end

  defp build_prompting_summary_block(session) do
    # Parse entries to count errors and new papers
    entries = Map.get(session, :entries, [])

    # Count parsing errors (displayed as warnings in UI)
    warning_count =
      entries
      |> Enum.count(fn entry ->
        case entry do
          %{"status" => "error"} -> true
          %{status: "error"} -> true
          _ -> false
        end
      end)

    new_paper_count =
      entries
      |> Enum.count(fn entry ->
        case entry do
          %{"status" => "new"} -> true
          %{status: "new"} -> true
          _ -> false
        end
      end)

    # Count duplicates
    duplicate_count =
      entries
      |> Enum.count(fn entry ->
        case entry do
          %{"status" => "duplicate"} -> true
          %{status: "duplicate"} -> true
          _ -> false
        end
      end)

    # Build the three buttons for the new UI
    summary_buttons = build_summary_buttons(warning_count, new_paper_count, duplicate_count)

    # Build action buttons - only continue button when there are new papers
    action_buttons =
      if new_paper_count > 0 do
        [
          %{
            action: %{type: :send, event: "commit_import"},
            face: %{type: :primary, label: dgettext("eyra-zircon", "import_view.button.continue")}
          }
        ]
      else
        []
      end

    {:prompting_summary,
     %{
       summary_text: dgettext("eyra-zircon", "import_view.prompting.found_in_file"),
       summary_buttons: summary_buttons,
       action_buttons: action_buttons,
       warning_count: warning_count,
       new_paper_count: new_paper_count,
       duplicate_count: duplicate_count,
       session_id: session.id
     }}
  end

  defp build_summary_buttons(warning_count, new_paper_count, duplicate_count) do
    buttons = []

    # Add warnings button if there are warnings
    buttons =
      if warning_count > 0 do
        warning_label =
          dngettext(
            "eyra-zircon",
            "1 warning",
            "%{count} warnings",
            warning_count,
            count: warning_count
          )

        buttons ++
          [
            %{
              action: %{type: :send, event: "show_warnings"},
              face: %{
                type: :plain,
                label: warning_label,
                icon: :details,
                icon_align: :left,
                text_color: "text-warning"
              }
            }
          ]
      else
        buttons
      end

    # Add new papers button if there are new papers
    buttons =
      if new_paper_count > 0 do
        new_papers_label =
          dngettext(
            "eyra-zircon",
            "1 new paper",
            "%{count} new papers",
            new_paper_count,
            count: new_paper_count
          )

        buttons ++
          [
            %{
              action: %{type: :send, event: "show_new_papers"},
              face: %{
                type: :plain,
                label: new_papers_label,
                icon: :details,
                icon_align: :left
              }
            }
          ]
      else
        buttons
      end

    # Add duplicates button if there are duplicates
    buttons =
      if duplicate_count > 0 do
        duplicates_label =
          dngettext(
            "eyra-zircon",
            "1 duplicate",
            "%{count} duplicates",
            duplicate_count,
            count: duplicate_count
          )

        buttons ++
          [
            %{
              action: %{type: :send, event: "show_duplicates"},
              face: %{
                type: :plain,
                label: duplicates_label,
                icon: :details,
                icon_align: :left
              }
            }
          ]
      else
        buttons
      end

    buttons
  end
end
