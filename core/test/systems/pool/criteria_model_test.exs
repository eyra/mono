defmodule Systems.Pool.CriteriaModelTest do
  use Core.DataCase, async: true

  alias Systems.Account
  alias Systems.Pool

  describe "eligitible?/2" do
    setup do
      features = %Account.FeaturesModel{
        gender: :man,
        birth_year: 1995,
        study_program_codes: [:vu_sbe_bk_1, :vu_sbe_bk_1_h]
      }

      {:ok, features: features}
    end

    test "eligitable without criteria", %{features: features} do
      criteria = %Pool.CriteriaModel{
        genders: nil
      }

      assert Pool.CriteriaModel.eligitable?(criteria, features)
    end

    test "eligitable with matching gender", %{features: features} do
      criteria = %Pool.CriteriaModel{
        genders: [:man]
      }

      assert Pool.CriteriaModel.eligitable?(criteria, features)
    end

    test "not eligitable without matching gender", %{features: features} do
      criteria = %Pool.CriteriaModel{
        genders: [:woman]
      }

      assert not Pool.CriteriaModel.eligitable?(criteria, features)
    end

    test "eligitable when criteria allows multiple genders including user's gender", %{
      features: features
    } do
      criteria = %Pool.CriteriaModel{
        genders: [:man, :woman]
      }

      assert Pool.CriteriaModel.eligitable?(criteria, features)
    end

    test "eligitable with no gender criteria" do
      criteria = %Pool.CriteriaModel{
        genders: []
      }

      features = %Account.FeaturesModel{
        gender: :woman,
        birth_year: 1990,
        study_program_codes: []
      }

      assert Pool.CriteriaModel.eligitable?(criteria, features)
    end
  end
end
