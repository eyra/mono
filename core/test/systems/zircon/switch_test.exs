defmodule Systems.Zircon.SwitchTest do
  use Core.DataCase

  alias Systems.Zircon.Switch
  alias Systems.Observatory.UpdateCollector

  setup do
    # Clear any leftover updates from previous tests
    UpdateCollector.clear()
    :ok
  end

  describe "processing_progress signal handling" do
    test "collects Observatory update for processing progress" do
      # Create test data
      reference_file = Core.Factories.insert!(:paper_reference_file)

      tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      paper_set =
        Core.Factories.insert!(:paper_set, %{
          category: :zircon_screening_tool,
          identifier: tool.id
        })

      # Create a session in processing phase with progress
      session =
        Core.Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :processing,
          progress: %{
            "current_reference" => 5,
            "total_references" => 10
          }
        })

      # Create the signal message
      message = %{
        paper_ris_import_session: session,
        from_pid: self()
      }

      # Verify no updates collected yet
      assert UpdateCollector.get_all() == []

      # Call the switch handler
      result = Switch.intercept({:paper_ris_import_session, :processing_progress}, message)

      # Should return :ok after processing
      assert result == :ok

      # Verify Observatory update was collected
      updates = UpdateCollector.get_all()
      assert length(updates) == 1

      # Verify the collected update structure
      [{target, args, collected_message}] = updates

      # Check target is correct
      assert target == {:embedded_live_view, Systems.Zircon.Screening.ImportView}

      # Check args contains tool id
      assert args == [tool.id]

      # Check message contains correct data
      assert collected_message.model.id == tool.id
      assert collected_message.from_pid == self()
      # Should not have batch_progress or processing_session - just model
      refute Map.has_key?(collected_message, :batch_progress)
      refute Map.has_key?(collected_message, :processing_session)
    end

    test "handles processing progress at different stages" do
      reference_file = Core.Factories.insert!(:paper_reference_file)

      tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      paper_set =
        Core.Factories.insert!(:paper_set, %{
          category: :zircon_screening_tool,
          identifier: tool.id
        })

      # Test various progress values
      test_cases = [
        {1, 100},
        {50, 100},
        {100, 100},
        {1, 1},
        {7, 12}
      ]

      for {current, total} <- test_cases do
        # Clear previous updates
        UpdateCollector.clear()

        session =
          Core.Factories.insert!(:paper_ris_import_session, %{
            paper_set: paper_set,
            reference_file: reference_file,
            status: :activated,
            phase: :processing,
            progress: %{
              "current_reference" => current,
              "total_references" => total
            }
          })

        message = %{
          paper_ris_import_session: session,
          from_pid: self()
        }

        result = Switch.intercept({:paper_ris_import_session, :processing_progress}, message)
        assert result == :ok, "Failed for progress #{current}/#{total}"

        # Verify update was collected
        updates = UpdateCollector.get_all()
        assert length(updates) == 1
      end
    end
  end

  describe "batch_completed signal handling with Observatory verification" do
    test "collects Observatory update with correct batch progress data" do
      # Create test data
      reference_file = Core.Factories.insert!(:paper_reference_file)

      tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      # Create the signal message with the structure that multi_dispatch creates
      message = %{
        update_progress_with_counts: %{
          reference_file_id: reference_file.id,
          progress: %{
            "current_batch" => 2,
            "total_batches" => 5,
            "papers_processed" => 200,
            "papers_imported" => 150,
            "papers_skipped" => 50,
            "total_papers" => 500
          }
        },
        from_pid: self()
      }

      # Verify no updates collected yet
      assert UpdateCollector.get_all() == []

      # Call the switch handler
      result = Switch.intercept({:paper_ris_import_session, :batch_completed}, message)

      # Should return :ok after processing
      assert result == :ok

      # Verify Observatory update was collected
      updates = UpdateCollector.get_all()
      assert length(updates) == 1

      # Verify the collected update structure
      [{target, args, collected_message}] = updates

      # Check target is correct
      assert target == {:embedded_live_view, Systems.Zircon.Screening.ImportView}

      # Check args contains tool id
      assert args == [tool.id]

      # Check message contains correct data
      assert collected_message.model.id == tool.id
      assert collected_message.from_pid == self()

      # Verify batch_progress has correct cumulative data
      batch_progress = collected_message.batch_progress
      assert batch_progress.batch_num == 2
      assert batch_progress.total_batches == 5
      assert batch_progress.papers_processed == 200
      assert batch_progress.papers_imported == 150
      assert batch_progress.papers_skipped == 50
      assert batch_progress.total_papers == 500
    end

    test "collects Observatory update with zero skipped papers" do
      reference_file = Core.Factories.insert!(:paper_reference_file)

      tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      message = %{
        update_progress_with_counts: %{
          reference_file_id: reference_file.id,
          progress: %{
            "current_batch" => 1,
            "total_batches" => 1,
            "papers_processed" => 100,
            "papers_imported" => 100,
            "papers_skipped" => 0,
            "total_papers" => 100
          }
        },
        from_pid: self()
      }

      result = Switch.intercept({:paper_ris_import_session, :batch_completed}, message)
      assert result == :ok

      # Verify Observatory update was collected
      updates = UpdateCollector.get_all()
      assert length(updates) == 1

      [{_target, args, collected_message}] = updates
      assert args == [tool.id]

      # Verify batch_progress shows zero skipped
      batch_progress = collected_message.batch_progress
      assert batch_progress.papers_imported == 100
      assert batch_progress.papers_skipped == 0
      assert batch_progress.total_papers == 100
    end

    test "handles batch_completed with all papers skipped" do
      reference_file = Core.Factories.insert!(:paper_reference_file)

      _tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      message = %{
        update_progress_with_counts: %{
          reference_file_id: reference_file.id,
          progress: %{
            "current_batch" => 1,
            "total_batches" => 1,
            "papers_processed" => 50,
            "papers_imported" => 0,
            "papers_skipped" => 50,
            "total_papers" => 50
          }
        },
        from_pid: self()
      }

      result = Switch.intercept({:paper_ris_import_session, :batch_completed}, message)
      assert result == :ok
    end

    test "correctly extracts progress data from session in message" do
      reference_file = Core.Factories.insert!(:paper_reference_file)

      _tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      # Test with various batch numbers and progress values
      test_cases = [
        {1, 3, 100, 80, 20, 300},
        {2, 3, 200, 160, 40, 300},
        {3, 3, 300, 240, 60, 300},
        {1, 1, 50, 50, 0, 50},
        {5, 10, 500, 450, 50, 1000}
      ]

      for {batch_num, total_batches, processed, imported, skipped, total} <- test_cases do
        message = %{
          update_progress_with_counts: %{
            reference_file_id: reference_file.id,
            progress: %{
              "current_batch" => batch_num,
              "total_batches" => total_batches,
              "papers_processed" => processed,
              "papers_imported" => imported,
              "papers_skipped" => skipped,
              "total_papers" => total
            }
          },
          from_pid: self()
        }

        result = Switch.intercept({:paper_ris_import_session, :batch_completed}, message)
        assert result == :ok, "Failed for batch #{batch_num}/#{total_batches}"
      end
    end
  end

  describe "other signal handling" do
    test "handles paper_reference_file updated signal" do
      # Create test data
      reference_file = Core.Factories.insert!(:paper_reference_file)

      tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      message = %{
        paper_reference_file: reference_file,
        from_pid: self()
      }

      result = Switch.intercept({:paper_reference_file, :updated}, message)

      # Should continue with the signal chain
      assert {:continue, :zircon_screening_tool, returned_tool} = result
      assert returned_tool.id == tool.id
    end

    test "handles paper_ris_import_session status changes" do
      reference_file = Core.Factories.insert!(:paper_reference_file)

      tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      paper_set =
        Core.Factories.insert!(:paper_set, %{
          category: :zircon_screening_tool,
          identifier: tool.id
        })

      session =
        Core.Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :succeeded,
          phase: :importing
        })

      message = %{
        paper_ris_import_session: session,
        from_pid: self()
      }

      # Test various status changes
      statuses = [
        :succeeded,
        :failed,
        :aborted,
        :waiting,
        :parsing,
        :processing,
        :prompting,
        :importing
      ]

      for status <- statuses do
        result = Switch.intercept({:paper_ris_import_session, status}, message)
        assert result == :ok, "Failed for status #{status}"
      end
    end

    test "handles zircon_screening_tool_annotation_assoc inserted signal" do
      tool = Core.Factories.insert!(:zircon_screening_tool)
      # Annotation requires a statement
      annotation = Core.Factories.insert!(:annotation, %{statement: "test"})

      assoc = %{
        tool: tool,
        annotation_id: annotation.id
      }

      message = %{
        zircon_screening_tool_annotation_assoc: assoc,
        from_pid: self()
      }

      result = Switch.intercept({:zircon_screening_tool_annotation_assoc, :inserted}, message)
      assert result == :ok
    end

    test "handles zircon_screening_tool_annotation_assoc deleted signal" do
      tool = Core.Factories.insert!(:zircon_screening_tool)

      message = %{
        zircon_screening_tool: tool,
        from_pid: self()
      }

      result = Switch.intercept({:zircon_screening_tool_annotation_assoc, :deleted}, message)
      assert result == :ok
    end

    test "handles zircon_screening_sessions invalidated signal" do
      sessions = ["session1", "session2", "session3"]

      message = %{
        zircon_screening_sessions: sessions,
        from_pid: self()
      }

      result = Switch.intercept({:zircon_screening_sessions, :invalidated}, message)
      assert result == :ok
    end
  end

  describe "edge cases" do
    test "handles missing progress data gracefully" do
      reference_file = Core.Factories.insert!(:paper_reference_file)

      _tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      # Message with empty progress map
      message = %{
        update_progress_with_counts: %{
          reference_file_id: reference_file.id,
          progress: %{}
        },
        from_pid: self()
      }

      # Should not crash, but might return nil values
      result = Switch.intercept({:paper_ris_import_session, :batch_completed}, message)
      assert result == :ok
    end

    test "handles nil values in progress data" do
      reference_file = Core.Factories.insert!(:paper_reference_file)

      _tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      message = %{
        update_progress_with_counts: %{
          reference_file_id: reference_file.id,
          progress: %{
            "current_batch" => nil,
            "total_batches" => nil,
            "papers_processed" => nil,
            "papers_imported" => nil,
            "papers_skipped" => nil,
            "total_papers" => nil
          }
        },
        from_pid: self()
      }

      result = Switch.intercept({:paper_ris_import_session, :batch_completed}, message)
      assert result == :ok
    end
  end
end
