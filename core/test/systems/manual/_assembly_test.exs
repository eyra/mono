defmodule Systems.Manual.AssemblyTest do
  use Core.DataCase

  alias Systems.Manual.Assembly

  describe "create_manual/0" do
    test "creates a manual with a chapter and a page" do
      assert {:ok, %{manual: %{chapters: [%{pages: [page | _]} = chapter | _]} = manual}} =
               Assembly.create_manual()

      assert manual.title == nil
      assert manual.description == nil
      assert manual.userflow_id
      assert chapter.title == "First chapter"
      assert chapter.userflow_step.group == "Example"
      assert page.title == "First page"
    end
  end
end
