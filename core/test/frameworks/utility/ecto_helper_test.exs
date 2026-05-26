defmodule Frameworks.Utility.EctoHelperTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset
  import Frameworks.Utility.EctoHelper, only: [apply_virtual_change: 4]

  defmodule TestSchema do
    use Ecto.Schema

    embedded_schema do
      field(:items, {:array, :string})
      field(:items_string, :string, virtual: true)
    end
  end

  defp changeset(data, params) do
    cast({data, %{items: {:array, :string}, items_string: :string}}, params, [:items_string])
  end

  describe "apply_virtual_change/4" do
    test "splits a non-empty virtual_string into the array field" do
      cs =
        %{items: ["old"], items_string: "old"}
        |> changeset(%{"items_string" => "a b c"})
        |> apply_virtual_change(:items, :items_string, [" ", ","])

      assert get_change(cs, :items) == ["a", "b", "c"]
    end

    test "clears the array field when the user empties the virtual string" do
      cs =
        %{items: ["old"], items_string: "old"}
        |> changeset(%{"items_string" => ""})
        |> apply_virtual_change(:items, :items_string, [" ", ","])

      assert get_change(cs, :items) == []
    end

    test "leaves the array field untouched when the virtual field is absent from params" do
      cs =
        %{items: ["old"], items_string: "old"}
        |> changeset(%{})
        |> apply_virtual_change(:items, :items_string, [" ", ","])

      assert get_change(cs, :items) == nil
    end
  end
end
