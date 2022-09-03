defmodule Systems.Pool.CriteriaModelTest do
  use Core.DataCase, async: true
  alias Core.Accounts.Features

  alias Systems.Pool.CriteriaModel

  describe "eligitible?/2" do
    setup do
      features = %Features{
        gender: :m,
        dominant_hand: :right,
        native_language: :nl,
        study_program_codes: [:vu_sbe_bk_1, :vu_sbe_bk_1_h]
      }

      {:ok, features: features}
    end

    test "eligitable without criteria", %{features: features} do
      criteria = %CriteriaModel{
        genders: nil,
        dominant_hands: nil,
        native_languages: nil
      }

      assert CriteriaModel.eligitable?(criteria, features)
    end

    test "eligitable with matching gender", %{features: features} do
      criteria = %CriteriaModel{
        genders: [:m],
        dominant_hands: nil,
        native_languages: nil
      }

      assert CriteriaModel.eligitable?(criteria, features)
    end

    test "not eligitable without matching gender", %{features: features} do
      criteria = %CriteriaModel{
        genders: [:v],
        dominant_hands: nil,
        native_languages: nil
      }

      assert not CriteriaModel.eligitable?(criteria, features)
    end

    test "eligitable with matching dominant hand", %{features: features} do
      criteria = %CriteriaModel{
        genders: [:m],
        dominant_hands: [:right],
        native_languages: nil
      }

      assert CriteriaModel.eligitable?(criteria, features)
    end

    test "not eligitable without matching dominant hand", %{features: features} do
      criteria = %CriteriaModel{
        genders: [:m],
        dominant_hands: [:left],
        native_languages: nil
      }

      assert not CriteriaModel.eligitable?(criteria, features)
    end

    test "eligitable with matching native language", %{features: features} do
      criteria = %CriteriaModel{
        genders: [:m],
        dominant_hands: [:right],
        native_languages: [:nl, :en]
      }

      assert CriteriaModel.eligitable?(criteria, features)
    end

    test "not eligitable without matching native language", %{features: features} do
      criteria = %CriteriaModel{
        genders: [:m],
        dominant_hands: [:right],
        native_languages: [:en]
      }

      assert not CriteriaModel.eligitable?(criteria, features)
    end
  end
end
