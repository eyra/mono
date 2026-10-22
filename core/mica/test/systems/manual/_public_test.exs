defmodule Systems.Manual.PublicTest do
  use Core.DataCase

  alias Systems.Manual
  alias Systems.Manual.Public
  alias Systems.Userflow

  describe "get!/1" do
    test "gets a manual by id" do
      manual = Manual.Factories.create_manual()
      fetched = Public.get_manual!(manual.id)
      assert fetched.id == manual.id
      # Preloaded
      assert fetched.userflow
    end

    test "raises for non-existent manual" do
      assert_raise Ecto.NoResultsError, fn ->
        Public.get_manual!(0)
      end
    end
  end

  describe "add_chapter/4" do
    test "adds a chapter to a manual" do
      manual = Manual.Factories.create_manual(1, 0)

      assert {:ok, %{manual_chapter: chapter}} = Public.add_chapter(manual)
      assert chapter.title == "New section"
      assert chapter.manual_id == manual.id
      assert chapter.userflow_id
    end
  end

  describe "get_chapters/1" do
    test "gets all chapters in a manual" do
      manual = Manual.Factories.create_manual(3, 1)

      fetched_chapters = Public.get_chapters(manual)
      assert length(fetched_chapters) == 3
      assert Enum.all?(fetched_chapters, &(&1.manual_id == manual.id))
    end

    test "returns empty list when no chapters" do
      userflow = Userflow.Factories.insert(:userflow)
      manual = Manual.Factories.insert(:manual, %{userflow: userflow})
      assert Public.get_chapters(manual) == []
    end
  end

  describe "add_page/4" do
    test "adds a page to a chapter" do
      %{chapters: [chapter | _]} = Manual.Factories.create_manual(2, 2)

      assert {:ok, %{manual_page: page}} = Public.add_page(chapter)
      assert page.title == "New instruction"
      assert page.userflow_step_id
    end
  end

  describe "next_chapter/2" do
    test "gets next unvisited chapter for user" do
      user = Core.Factories.insert!(:member)
      manual = %{chapters: [chapter | _]} = Manual.Factories.create_manual(2, 2)
      next = Public.next_chapter(manual, user)
      assert next.id == chapter.id
    end

    test "returns nil when all chapters visited" do
      user = Core.Factories.insert!(:member)
      manual = Manual.Factories.create_manual(2, 2)

      # Mark all chapters as visited
      Enum.each(Public.get_chapters(manual), fn chapter ->
        Public.mark_visited(chapter, user)
      end)

      assert Public.next_chapter(manual, user) == nil
    end
  end

  describe "finished_chapters?/2" do
    test "returns true when all chapters are visited" do
      user = Core.Factories.insert!(:member)
      manual = Manual.Factories.create_manual(2, 2)
      chapters = Public.get_chapters(manual)

      # Mark all chapters as visited
      Enum.each(chapters, fn chapter ->
        Public.mark_visited(chapter, user)
      end)

      assert Public.finished_chapters?(manual, user.id)
    end

    test "returns false when not all chapters are visited" do
      user = Core.Factories.insert!(:member)
      manual = Manual.Factories.create_manual(2, 2)
      refute Public.finished_chapters?(manual, user.id)
    end
  end

  describe "chapters_by_group/1" do
    test "groups chapters by their group field" do
      ExMachina.Sequence.reset()

      manual = Manual.Factories.create_manual(3, 3)

      groups = Public.chapters_by_group(manual)
      assert map_size(groups) == 2
      assert length(groups["group-chapter-0"]) == 1
      assert length(groups["group-chapter-1"]) == 2
    end
  end

  describe "get_chapter_progress/2" do
    test "gets progress for user in manual chapters" do
      user = Core.Factories.insert!(:member)
      manual = %{chapters: [chapter | _]} = Manual.Factories.create_manual(2, 2)

      # Mark first chapter as visited
      Public.mark_visited(chapter, user)

      progress = Public.list_progress(manual, user.id)
      assert length(progress) == 1
      assert hd(progress).user_id == user.id
    end
  end

  describe "page/2" do
    test "updates a page's content" do
      %{chapters: [%{pages: [page | _]} | _]} = Manual.Factories.create_manual(1, 1)

      attrs = %{title: "Updated Title"}
      assert {:ok, updated} = Public.update_page(page, attrs)
      assert updated.title == "Updated Title"
    end
  end
end
