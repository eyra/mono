defmodule Core.Pools.CriteriaTest do
  use Core.DataCase, async: true
  alias Core.Pools.Criteria
  alias Core.Accounts.Features

  describe "eligitible?/2" do
    setup do
      features = %Features{
        gender: :m,
        dominant_hand: :right,
        native_language: :nl,
        study_program_codes: [:bk_1, :bk_1_h]
      }

      {:ok, features: features}
    end

    test "eligitable without criteria", %{features: features} do
      criteria = %Criteria{
        genders: nil,
        dominant_hands: nil,
        native_languages: nil,
        study_program_codes: nil
      }

      assert Criteria.eligitable?(criteria, features)
    end

    test "eligitable with matching gender", %{features: features} do
      criteria = %Criteria{
        genders: [:m],
        dominant_hands: nil,
        native_languages: nil,
        study_program_codes: nil
      }

      assert Criteria.eligitable?(criteria, features)
    end

    test "not eligitable without matching gender", %{features: features} do
      criteria = %Criteria{
        genders: [:v],
        dominant_hands: nil,
        native_languages: nil,
        study_program_codes: nil
      }

      assert not Criteria.eligitable?(criteria, features)
    end

    test "eligitable with matching dominant hand", %{features: features} do
      criteria = %Criteria{
        genders: [:m],
        dominant_hands: [:right],
        native_languages: nil,
        study_program_codes: nil
      }

      assert Criteria.eligitable?(criteria, features)
    end

    test "not eligitable without matching dominant hand", %{features: features} do
      criteria = %Criteria{
        genders: [:m],
        dominant_hands: [:left],
        native_languages: nil,
        study_program_codes: nil
      }

      assert not Criteria.eligitable?(criteria, features)
    end

    test "eligitable with matching native language", %{features: features} do
      criteria = %Criteria{
        genders: [:m],
        dominant_hands: [:right],
        native_languages: [:nl, :en],
        study_program_codes: nil
      }

      assert Criteria.eligitable?(criteria, features)
    end

    test "not eligitable without matching native language", %{features: features} do
      criteria = %Criteria{
        genders: [:m],
        dominant_hands: [:right],
        native_languages: [:en],
        study_program_codes: nil
      }

      assert not Criteria.eligitable?(criteria, features)
    end

    test "eligitable with matching study_program_codes", %{features: features} do
      criteria = %Criteria{
        genders: [:m],
        dominant_hands: [:right],
        native_languages: [:nl, :en],
        study_program_codes: [:bk_1, :bk_2]
      }

      assert Criteria.eligitable?(criteria, features)
    end

    test "not eligitable without matching study_program_codes", %{features: features} do
      criteria = %Criteria{
        genders: [:m],
        dominant_hands: [:right],
        native_languages: [:en],
        study_program_codes: [:bk_2, :bk_2_h]
      }

      assert not Criteria.eligitable?(criteria, features)
    end
  end
end
