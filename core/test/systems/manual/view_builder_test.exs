defmodule Systems.Manual.ViewBuilderTest do
  use Core.DataCase

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
