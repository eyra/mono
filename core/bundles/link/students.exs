# Script for populating the database. You can run it as:
#
#     mix run priv/repo/students.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Core.Repo.insert!(%Link.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
#
#
bk_1_student_count = 100
bk_1_h_student_count = 10
bk_2_student_count = 100
bk_2_h_student_count = 10
iba_1_student_count = 100
iba_1_h_student_count = 10
iba_2_student_count = 100
iba_2_h_student_count = 10

password = "asdf;lkjASDF0987"

{:ok, students} =
  Core.Repo.transaction(fn ->
    for _ <- 1..bk_1_student_count do
      attrs = %{
        student: true,
        password: password,
        features: %Core.Accounts.Features{
          study_program_codes: [:vu_sbe_bk_1]
        }
      }

      Core.Factories.insert!(:student, attrs)
    end

    for _ <- 1..bk_1_h_student_count do
      attrs = %{
        student: true,
        password: password,
        features: %Core.Accounts.Features{
          study_program_codes: [:vu_sbe_bk_1_h]
        }
      }

      Core.Factories.insert!(:student, attrs)
    end

    for _ <- 1..bk_2_student_count do
      attrs = %{
        student: true,
        password: password,
        features: %Core.Accounts.Features{
          study_program_codes: [:bk_2]
        }
      }

      Core.Factories.insert!(:student, attrs)
    end

    for _ <- 1..bk_2_h_student_count do
      attrs = %{
        student: true,
        password: password,
        features: %Core.Accounts.Features{
          study_program_codes: [:bk_2_h]
        }
      }

      Core.Factories.insert!(:student, attrs)
    end

    for _ <- 1..iba_1_student_count do
      attrs = %{
        student: true,
        password: password,
        features: %Core.Accounts.Features{
          study_program_codes: [:iba_1]
        }
      }

      Core.Factories.insert!(:student, attrs)
    end

    for _ <- 1..iba_1_h_student_count do
      attrs = %{
        student: true,
        password: password,
        features: %Core.Accounts.Features{
          study_program_codes: [:iba_1_h]
        }
      }

      Core.Factories.insert!(:student, attrs)
    end

    for _ <- 1..iba_2_student_count do
      attrs = %{
        student: true,
        password: password,
        features: %Core.Accounts.Features{
          study_program_codes: [:iba_2]
        }
      }

      Core.Factories.insert!(:student, attrs)
    end

    for _ <- 1..iba_2_h_student_count do
      attrs = %{
        student: true,
        password: password,
        features: %Core.Accounts.Features{
          study_program_codes: [:iba_2_h]
        }
      }

      Core.Factories.insert!(:student, attrs)
    end
  end)
