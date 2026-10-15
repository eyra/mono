defmodule Frameworks.Concept.Special do
  import Ecto.Changeset

  def field_value(model, special_fields) do
    if field = field(model, special_fields) do
      Map.get(model, field)
    else
      nil
    end
  end

  def field_id(model, special_fields) do
    if field = field(model, special_fields) do
      map_to_field_id(field)
    else
      nil
    end
  end

  def field(model, special_fields) do
    Enum.reduce(special_fields, nil, fn field, acc ->
      field_id = map_to_field_id(field)

      if Map.get(model, field_id) != nil do
        field
      else
        acc
      end
    end)
  end

  def change(changeset, special_field, special, special_fields) when is_atom(special_field) do
    specials =
      Enum.map(
        special_fields,
        &{&1,
         if &1 == special_field do
           special
         else
           nil
         end}
      )

    changeset
    |> then(
      &Enum.reduce(specials, &1, fn {field, value}, changeset ->
        put_assoc(changeset, field, value)
      end)
    )
  end

  defp map_to_field_id(field), do: String.to_existing_atom("#{field}_id")

  defmacro __using__(special_fields) do
    quote do
      alias Frameworks.Concept.Special

      def special(model) do
        Special.field_value(model, unquote(special_fields))
      end

      def special_field_id(model) do
        Special.field_id(model, unquote(special_fields))
      end

      def special_field(model) do
        Special.field(model, unquote(special_fields))
      end

      def change_special(changeset, special_field, special) do
        Special.change(changeset, special_field, special, unquote(special_fields))
      end
    end
  end
end
