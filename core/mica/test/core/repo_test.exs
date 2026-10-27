defmodule Core.RepoTest do
  use Core.DataCase

  alias Core.Repo
  alias Core.Factories
  alias Ecto.Multi

  describe "multi_update_guard/3" do
    setup do
      %{info: Factories.insert!(:assignment_info, %{subject_count: 1})}
    end

    test "passes when the model is up to date", %{info: info} do
      assert {:ok, %{"assignment_info_up_to_date?" => true}} =
               Multi.new()
               |> Repo.multi_update_guard(:assignment_info, info)
               |> Repo.commit()
    end

    test "returns an error for a stale model with an atom name", %{info: info} do
      stale = %{info | updated_at: ~N[2000-01-01 00:00:00]}

      assert {:error, "assignment_info_up_to_date?",
              "Assignment_info is not up to date, preventing database change", _} =
               Multi.new()
               |> Repo.multi_update_guard(:assignment_info, stale)
               |> Repo.commit()
    end

    test "returns an error for a stale model with a string name", %{info: info} do
      stale = %{info | updated_at: ~N[2000-01-01 00:00:00]}

      assert {:error, "info_up_to_date?", "Info is not up to date, preventing database change", _} =
               Multi.new()
               |> Repo.multi_update_guard("info", stale)
               |> Repo.commit()
    end
  end

  describe "multi_update/3" do
    test "does not update a stale model" do
      info = Factories.insert!(:assignment_info, %{subject_count: 1})
      stale = %{info | updated_at: ~N[2000-01-01 00:00:00]}
      changeset = Ecto.Changeset.change(stale, subject_count: 2)

      assert {:error, "assignment_info_up_to_date?", _, _} =
               Multi.new()
               |> Repo.multi_update(:assignment_info, changeset)
               |> Repo.commit()

      assert %{subject_count: 1} = Repo.get!(Systems.Assignment.InfoModel, info.id)
    end
  end

  describe "orphan?" do
    test "returns true if the entity is not referred to by any other entity" do
      annotation = Factories.insert!(:annotation, %{statement: "test"})
      assert Repo.orphan?(annotation, ignore: [Systems.Annotation.Assoc])
    end

    test "returns false if the Systems.Annotation.Assoc association table is not ignored" do
      # Annotation.Model -> Annotation.RefModel goes through the Systems.Annotation.Assoc association table.
      # By not ignoring the Systems.Annotation.Assoc association table, an annotation with at least one reference
      # will not be considered orphaned. The association table has a reference to this annotation.
      # This is a general phenomenon with association schemas.

      annotation1 = Factories.insert!(:annotation, %{statement: "test"})
      annotation_ref1 = Factories.insert!(:annotation_ref, %{annotation: annotation1})

      annotation2 =
        Factories.insert!(:annotation, %{statement: "test", references: [annotation_ref1]})

      assert not Repo.orphan?(annotation2, ignore: [])
    end

    test "returns false if the entity is referred to by another entity" do
      annotation1 = Factories.insert!(:annotation, %{statement: "test"})
      annotation_ref1 = Factories.insert!(:annotation_ref, %{annotation: annotation1})

      annotation2 =
        Factories.insert!(:annotation, %{statement: "test", references: [annotation_ref1]})

      annotation_ref2 = Factories.insert!(:annotation_ref, %{annotation: annotation2})

      annotation3 =
        Factories.insert!(:annotation, %{statement: "test", references: [annotation_ref2]})

      assert not Repo.orphan?(annotation1, ignore: [Systems.Annotation.Assoc])
      assert not Repo.orphan?(annotation2, ignore: [Systems.Annotation.Assoc])
      assert Repo.orphan?(annotation3, ignore: [Systems.Annotation.Assoc])
    end
  end
end
