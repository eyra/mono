defmodule Systems.Manual.ViewBuilderTest do
  # `async: true` runs each test in Ecto's ownership mode instead of the
  # shared mode DataCase defaults to. The test only does synchronous DB
  # inserts + pure view-model building — no signals, no LiveView, no
  # spawned processes — so it's safe to isolate. Without this, the test
  # was racing other non-async DataCase tests on the global shared sandbox
  # owner registration, producing intermittent
  # `DBConnection.ConnectionError{message: "client #PID<…> exited"}`
  # during setup. (FX#9998325274)
  use Core.DataCase, async: true

  alias Systems.Manual

  describe "view_model/2" do
    setup do
      user = Factories.insert!(:member)
      manual = Manual.Factories.create_manual(2, 1)
      [chapter1, chapter2] = manual.chapters

      %{user: user, manual: manual, chapter1: chapter1, chapter2: chapter2}
    end

    test "builds chapter_list_view when chapter is nil", %{user: user, manual: manual} do
      assigns = %{
        title: "Test Manual",
        current_user: user,
        presentation: :modal,
        user_state: %{chapter: nil, page: nil}
      }

      vm = Manual.ViewBuilder.view_model(manual, assigns)

      assert vm.selected_chapter_id == nil
      assert vm.selected_chapter == nil
      assert vm.chapter_view == nil

      # chapter_list_view should be a LiveNest Element
      assert %LiveNest.Element{} = vm.chapter_list_view
      assert vm.chapter_list_view.implementation == Manual.ChapterListView
      assert vm.chapter_list_view.id == :chapter_list
    end

    test "builds chapter_view when chapter is selected", %{
      user: user,
      manual: manual,
      chapter1: chapter1
    } do
      assigns = %{
        title: "Test Manual",
        current_user: user,
        presentation: :modal,
        user_state: %{chapter: chapter1.id, page: nil}
      }

      vm = Manual.ViewBuilder.view_model(manual, assigns)

      assert vm.selected_chapter_id == chapter1.id
      assert vm.selected_chapter.id == chapter1.id

      # chapter_view should be a LiveNest Element
      assert %LiveNest.Element{} = vm.chapter_view
      assert vm.chapter_view.implementation == Manual.ChapterView
      assert vm.chapter_view.id == :chapter

      # chapter_list_view should still be present
      assert %LiveNest.Element{} = vm.chapter_list_view
    end

    test "loads selected chapter from a chapter-list preload", %{
      user: user,
      manual: manual,
      chapter1: chapter1
    } do
      manual =
        Manual.Public.get_manual!(manual.id, Manual.Model.preload_graph(:chapter_list))

      [chapter | _] = manual.chapters
      assert %Ecto.Association.NotLoaded{} = chapter.pages

      assigns = %{
        title: "Test Manual",
        current_user: user,
        presentation: :modal,
        user_state: %{chapter: chapter1.id, page: nil}
      }

      vm = Manual.ViewBuilder.view_model(manual, assigns)

      assert vm.selected_chapter.id == chapter1.id
      assert [_page] = vm.selected_chapter.pages
    end

    test "loads pages for a newly selected chapter", %{
      user: user,
      manual: manual,
      chapter1: chapter1,
      chapter2: chapter2
    } do
      manual =
        Manual.Public.get_manual!(manual.id, Manual.Model.preload_graph(:chapter_list))

      assigns = %{
        title: "Test Manual",
        current_user: user,
        presentation: :modal,
        user_state: %{chapter: chapter1.id, page: nil}
      }

      vm = Manual.ViewBuilder.view_model(manual, assigns)
      assert vm.selected_chapter.id == chapter1.id
      assert [%{chapter_id: chapter1_id}] = vm.selected_chapter.pages
      assert chapter1_id == chapter1.id

      vm =
        Manual.ViewBuilder.view_model(vm.manual, %{
          assigns
          | user_state: %{chapter: chapter2.id, page: nil}
        })

      assert vm.selected_chapter.id == chapter2.id
      assert [%{chapter_id: chapter2_id}] = vm.selected_chapter.pages
      assert chapter2_id == chapter2.id
    end

    test "loads every page of a selected chapter", %{user: user} do
      manual = Manual.Factories.create_manual(1, 3)
      [chapter] = manual.chapters

      manual =
        Manual.Public.get_manual!(manual.id, Manual.Model.preload_graph(:chapter_list))

      vm =
        Manual.ViewBuilder.view_model(manual, %{
          title: "Test Manual",
          current_user: user,
          presentation: :modal,
          user_state: %{chapter: chapter.id, page: nil}
        })

      assert Enum.map(vm.selected_chapter.pages, & &1.id) ==
               chapter.pages
               |> Enum.sort_by(& &1.userflow_step.order)
               |> Enum.map(& &1.id)
    end

    test "selects correct chapter from multiple chapters", %{
      user: user,
      manual: manual,
      chapter2: chapter2
    } do
      assigns = %{
        title: "Test Manual",
        current_user: user,
        presentation: :modal,
        user_state: %{chapter: chapter2.id, page: nil}
      }

      vm = Manual.ViewBuilder.view_model(manual, assigns)

      assert vm.selected_chapter_id == chapter2.id
      assert vm.selected_chapter.id == chapter2.id
    end

    test "chapters are sorted by userflow step order", %{user: user, manual: manual} do
      assigns = %{
        title: "Test Manual",
        current_user: user,
        presentation: :modal,
        user_state: %{chapter: nil, page: nil}
      }

      vm = Manual.ViewBuilder.view_model(manual, assigns)

      [first, second] = vm.chapters
      assert first.userflow_step.order < second.userflow_step.order
    end
  end
end
