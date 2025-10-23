defmodule Annotation.PublicTest do
  use Core.DataCase

  import Systems.Annotation.Public

  alias Systems.Annotation

  setup do
    user = Factories.insert!(:member)

    entity =
      Factories.insert!(:authentication_entity, %{identifier: "System.Account.User:#{user.id}"})

    annotation_type = Factories.insert!(:ontology_concept, %{phrase: "Comment", entity: entity})

    %{entity: entity, annotation_type: annotation_type}
  end

  test "insert_annotation/5 insert annotation on existing annotation", %{
    entity: entity,
    annotation_type: type
  } do
    ref = Factories.insert!(:annotation, %{statement: "Parent annotation"})

    assert {:ok, %{annotation: %Annotation.Model{}}} =
             insert_annotation(type, "Comment on existing annotation", entity, ref)
  end

  test "insert_annotation/5 insert annotation on existing concept", %{
    entity: entity,
    annotation_type: type
  } do
    ref = Factories.insert!(:ontology_concept, %{phrase: "Existing concept"})

    assert {:ok, %{annotation: %Annotation.Model{}}} =
             insert_annotation(type, "Comment on existing concept", entity, ref)
  end

  test "insert_annotation/5 insert annotation on existing predicate", %{
    entity: entity,
    annotation_type: type
  } do
    predicate = Factories.insert!(:ontology_predicate)

    assert {:ok, %{annotation: %Annotation.Model{}}} =
             insert_annotation(type, "Comment on existing predicate", entity, predicate)
  end

  test "insert_annotation/5 insert nil reference", %{
    entity: entity,
    annotation_type: type
  } do
    assert_raise FunctionClauseError, fn ->
      insert_annotation(type, "Comment on nil reference", entity, nil)
    end
  end

  test "insert_annotation/5 insert nil value", %{
    entity: entity,
    annotation_type: type
  } do
    ref = Factories.insert!(:ontology_concept, %{phrase: "Existing concept"})
    {:error, :annotation, changeset, _} = insert_annotation(type, nil, entity, ref)

    assert [
             statement: {"can't be blank", [validation: :required]}
           ] = changeset.errors
  end

  test "insert_annotation/5 insert nil author", %{
    annotation_type: type
  } do
    assert_raise Postgrex.Error, fn ->
      ref = Factories.insert!(:ontology_concept, %{phrase: "Existing concept"})
      insert_annotation(type, "Comment with nil entity", nil, ref)
    end
  end

  test "insert_annotation/5 insert + insert (different statements)", %{
    entity: entity,
    annotation_type: type
  } do
    ref = Factories.insert!(:annotation, %{statement: "Parent annotation"})

    assert {:ok, %{annotation: annotation1}} =
             insert_annotation(type, "Comment 1 on existing annotation", entity, ref)

    assert {:ok, %{annotation: annotation2}} =
             insert_annotation(type, "Comment 2 on existing annotation", entity, ref)

    assert annotation1.id != annotation2.id
  end

  test "insert_annotation/5 insert + insert (different authors)", %{
    entity: entity,
    annotation_type: type
  } do
    user2 = Factories.insert!(:member)

    entity2 =
      Factories.insert!(:authentication_entity, %{identifier: "System.Account.User:#{user2.id}"})

    ref = Factories.insert!(:annotation, %{statement: "Parent annotation"})

    assert {:ok, %{annotation: annotation1}} =
             insert_annotation(type, "Comment on existing annotation", entity, ref)

    assert {:ok, %{annotation: annotation2}} =
             insert_annotation(type, "Comment on existing annotation", entity2, ref)

    assert annotation1.id != annotation2.id
  end

  test "insert_annotation/5 insert + insert (same statement)", %{
    entity: entity,
    annotation_type: type
  } do
    ref = Factories.insert!(:annotation, %{statement: "Parent annotation"})

    assert {:ok, %{annotation: annotation_1}} =
             insert_annotation(type, "Comment on existing annotation", entity, ref)

    assert {:ok, %{annotation: annotation_2}} =
             insert_annotation(type, "Comment on existing annotation", entity, ref)

    assert annotation_1.id != annotation_2.id
  end
end
