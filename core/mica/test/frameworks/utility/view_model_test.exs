defmodule Frameworks.Utility.ViewModelTest do
  use Core.DataCase

  alias Frameworks.Utility.ViewModel

  describe "merge/3" do
    test "merge :append" do
      vm1 = %{field: [1]}
      vm2 = %{field: [2]}
      %{field: field} = ViewModel.merge(vm1, vm2, :append)
      assert field == [1, 2]
    end

    test "merge :overwrite" do
      vm1 = %{field: [1]}
      vm2 = %{field: [2]}
      %{field: field} = ViewModel.merge(vm1, vm2, :overwrite)
      assert field == [2]
    end

    test "merge :skip" do
      vm1 = %{field: [1]}
      vm2 = %{field: [2]}
      %{field: field} = ViewModel.merge(vm1, vm2, :skip)
      assert field == [1]
    end
  end

  describe "append/3" do
    test "append with nil" do
      vm = %{field: 1}
      %{field: field} = ViewModel.append(vm, :field, nil)
      assert field == 1
    end

    test "append to non existing field" do
      vm = %{}
      %{field: field} = ViewModel.append(vm, :field, [2])
      assert field == [2]
    end

    test "append to list" do
      vm = %{field: [1]}
      %{field: field} = ViewModel.append(vm, :field, [2])
      assert field == [1, 2]
    end

    test "append to map" do
      vm = %{field: %{key1: 1, key2: 2}}
      %{field: field} = ViewModel.append(vm, :field, %{key3: 3})
      assert field == %{key1: 1, key2: 2, key3: 3}
    end
  end

  describe "required/3" do
    test "required applied" do
      vm = %{}
      %{field: field} = ViewModel.required(vm, :field, 2)
      assert field == 2
    end

    test "required not applied" do
      vm = %{field: 1}
      %{field: field} = ViewModel.required(vm, :field, 2)
      assert field == 1
    end
  end
end
