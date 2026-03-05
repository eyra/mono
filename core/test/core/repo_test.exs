defmodule Core.RepoTest do
  use Core.DataCase

  alias Core.Factories
  alias Core.Repo
  alias Systems.Annotation.Assoc

  describe "orphan?" do
    test "returns true if the entity is not referred to by any other entity" do
      annotation = Factories.insert!(:annotation, %{statement: "test"})
      assert Repo.orphan?(annotation, ignore: [Assoc])
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

      refute Repo.orphan?(annotation2, ignore: [])
    end

    test "returns false if the entity is referred to by another entity" do
      annotation1 = Factories.insert!(:annotation, %{statement: "test"})
      annotation_ref1 = Factories.insert!(:annotation_ref, %{annotation: annotation1})

      annotation2 =
        Factories.insert!(:annotation, %{statement: "test", references: [annotation_ref1]})

      annotation_ref2 = Factories.insert!(:annotation_ref, %{annotation: annotation2})

      annotation3 =
        Factories.insert!(:annotation, %{statement: "test", references: [annotation_ref2]})

      refute Repo.orphan?(annotation1, ignore: [Assoc])
      refute Repo.orphan?(annotation2, ignore: [Assoc])
      assert Repo.orphan?(annotation3, ignore: [Assoc])
    end
  end
end
