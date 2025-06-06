defmodule Annotation.PublicTest do
  use Core.DataCase

  import Systems.Annotation.Public

  alias Systems.Annotation

  setup do
    author = Factories.insert!(:member)
    annotation_type = Factories.insert!(:ontology_concept, %{phrase: "Comment"})
    annotation_ref_type = Factories.insert!(:ontology_concept, %{phrase: "Subject"})
    %{author: author, annotation_type: annotation_type, annotation_ref_type: annotation_ref_type}
  end

  test "insert_annotation/5 insert annotation on existing annotation", %{
    author: author,
    annotation_type: type,
    annotation_ref_type: ref_type
  } do
    ref = Factories.insert!(:annotation, %{statement: "Parent annotation"})

    assert {:ok, %{annotation: %Annotation.Model{}}} =
             insert_annotation(type, "Comment on existing annotation", author, ref_type, ref)
  end

  test "insert_annotation/5 insert annotation on existing concept", %{
    author: author,
    annotation_type: type,
    annotation_ref_type: ref_type
  } do
    ref = Factories.insert!(:ontology_concept, %{phrase: "Existing concept"})

    assert {:ok, %{annotation: %Annotation.Model{}}} =
             insert_annotation(type, "Comment on existing concept", author, ref_type, ref)
  end

  test "insert_annotation/5 insert annotation on existing predicate", %{
    author: author,
    annotation_type: type,
    annotation_ref_type: ref_type
  } do
    predicate = Factories.insert!(:ontology_predicate)

    assert {:ok, %{annotation: %Annotation.Model{}}} =
             insert_annotation(type, "Comment on existing predicate", author, ref_type, predicate)
  end

  test "insert_annotation/5 insert nil reference", %{
    author: author,
    annotation_type: type,
    annotation_ref_type: ref_type
  } do
    assert_raise FunctionClauseError, fn ->
      insert_annotation(type, "Comment on nil reference", author, ref_type, nil)
    end
  end

  test "insert_annotation/5 insert nil value", %{
    author: author,
    annotation_type: type,
    annotation_ref_type: ref_type
  } do
    ref = Factories.insert!(:ontology_concept, %{phrase: "Existing concept"})
    {:error, :annotation, changeset, _} = insert_annotation(type, nil, author, ref_type, ref)

    assert [
             statement: {"can't be blank", [validation: :required]}
           ] = changeset.errors
  end

  test "insert_annotation/5 insert nil author", %{
    annotation_type: type,
    annotation_ref_type: ref_type
  } do
    assert_raise Postgrex.Error, fn ->
      ref = Factories.insert!(:ontology_concept, %{phrase: "Existing concept"})
      insert_annotation(type, "Comment with nil user", nil, ref_type, ref)
    end
  end

  test "insert_annotation/5 insert + insert (different statements)", %{
    author: author,
    annotation_type: type,
    annotation_ref_type: ref_type
  } do
    ref = Factories.insert!(:annotation, %{statement: "Parent annotation"})

    assert {:ok, %{annotation: annotation1}} =
             insert_annotation(type, "Comment 1 on existing annotation", author, ref_type, ref)

    assert {:ok, %{annotation: annotation2}} =
             insert_annotation(type, "Comment 2 on existing annotation", author, ref_type, ref)

    assert annotation1.id != annotation2.id
  end

  test "insert_annotation/5 insert + insert (different authors)", %{
    author: author,
    annotation_type: type,
    annotation_ref_type: ref_type
  } do
    author2 = Factories.insert!(:member)
    ref = Factories.insert!(:annotation, %{statement: "Parent annotation"})

    assert {:ok, %{annotation: annotation1}} =
             insert_annotation(type, "Comment on existing annotation", author, ref_type, ref)

    assert {:ok, %{annotation: annotation2}} =
             insert_annotation(type, "Comment on existing annotation", author2, ref_type, ref)

    assert annotation1.id != annotation2.id
  end

  test "insert_annotation/5 insert + insert (different ai_generated?)", %{
    author: author,
    annotation_type: type,
    annotation_ref_type: ref_type
  } do
    ref = Factories.insert!(:annotation, %{statement: "Parent annotation"})

    assert {:ok, %{annotation: annotation1}} =
             insert_annotation(type, "Comment on existing annotation", author, ref_type, ref)

    assert {:ok, %{annotation: annotation2}} =
             insert_annotation(type, "Comment on existing annotation", author, ref_type, ref,
               ai_generated?: true
             )

    assert annotation1.id != annotation2.id
  end

  test "insert_annotation/5 insert + insert (same statement)", %{
    author: author,
    annotation_type: type,
    annotation_ref_type: ref_type
  } do
    ref = Factories.insert!(:annotation, %{statement: "Parent annotation"})

    assert {:ok, %{annotation: annotation_1}} =
             insert_annotation(type, "Comment on existing annotation", author, ref_type, ref)

    assert {:ok, %{annotation: annotation_2}} =
             insert_annotation(type, "Comment on existing annotation", author, ref_type, ref)

    assert annotation_1.id != annotation_2.id
  end
end
