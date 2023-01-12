defmodule Systems.Scholar.ExportControllerTest do
  use Core.DataCase

  alias Systems.{
    Scholar,
    Budget
  }

  test "export/2 with 1 student, 1 pool" do
    currency_name = "vu_sbe_rpr_year1_2022"
    currency = Budget.Factories.create_currency(currency_name, "credits", 0)

    student_id1 = "12345678"
    student1 = create_surfconext_student(student_id1)
    credits1 = 10

    Factories.insert!(:book_account, %{
      identifier: ["wallet", currency_name, "#{student1.user.id}"],
      balance_credit: credits1,
      balance_debit: 0
    })

    pool = Factories.insert!(:pool, %{name: currency_name, target: 100, currency: currency})

    row1 = "#{student_id1},#{student1.email},#{student1.user.profile.fullname},#{credits1}\r\n"

    assert [
             "studentid,email,name,credits\r\n",
             ^row1
           ] = Scholar.ExportController.export([student1.user], pool)
  end

  test "export/2 with 1 invalid student, 1 pool" do
    currency_name = "vu_sbe_rpr_year1_2022"
    currency = Budget.Factories.create_currency(currency_name, "credits", 0)

    student1 =
      Factories.insert!(:surfconext_student, %{
        schac_personal_unique_code: "urn:schac:personalUniqueCode:nl:local:vu.nl:invalid:12345678"
      })

    credits1 = 10

    Factories.insert!(:book_account, %{
      identifier: ["wallet", currency_name, "#{student1.user.id}"],
      balance_credit: credits1,
      balance_debit: 0
    })

    pool = Factories.insert!(:pool, %{name: currency_name, target: 100, currency: currency})

    row1 = ",#{student1.email},#{student1.user.profile.fullname},#{credits1}\r\n"

    assert [
             "studentid,email,name,credits\r\n",
             ^row1
           ] = Scholar.ExportController.export([student1.user], pool)
  end

  test "export/2 with 2 students, 1 pool" do
    currency_name = "vu_sbe_rpr_year1_2022"
    currency = Budget.Factories.create_currency(currency_name, "credits", 0)

    student_id1 = "123"
    student1 = create_surfconext_student(student_id1)
    credits1 = 10

    Factories.insert!(:book_account, %{
      identifier: ["wallet", currency_name, "#{student1.user.id}"],
      balance_credit: credits1,
      balance_debit: 0
    })

    student_id2 = "456"
    student2 = create_surfconext_student(student_id2)
    credits2 = 5

    Factories.insert!(:book_account, %{
      identifier: ["wallet", currency_name, "#{student2.user.id}"],
      balance_credit: credits2,
      balance_debit: 0
    })

    pool = Factories.insert!(:pool, %{name: currency_name, target: 100, currency: currency})

    row1 = "#{student_id1},#{student1.email},#{student1.user.profile.fullname},#{credits1}\r\n"
    row2 = "#{student_id2},#{student2.email},#{student2.user.profile.fullname},#{credits2}\r\n"

    assert [
             "studentid,email,name,credits\r\n",
             ^row1,
             ^row2
           ] = Scholar.ExportController.export([student1.user, student2.user], pool)
  end

  test "export/2 with 2 students, 2 pools" do
    currency_name1 = "vu_sbe_rpr_year1_2022"
    currency1 = Budget.Factories.create_currency(currency_name1, "credits", 0)

    currency_name2 = "vu_sbe_rpr_year2_2022"
    currency2 = Budget.Factories.create_currency(currency_name2, "credits", 0)

    student_id1 = "123"
    student1 = create_surfconext_student(student_id1)
    credits1 = 10

    Factories.insert!(:book_account, %{
      identifier: ["wallet", currency_name1, "#{student1.user.id}"],
      balance_credit: credits1,
      balance_debit: 0
    })

    student_id2 = "456"
    student2 = create_surfconext_student(student_id2)
    credits2 = 10

    Factories.insert!(:book_account, %{
      identifier: ["wallet", currency_name2, "#{student2.user.id}"],
      balance_credit: credits2,
      balance_debit: 0
    })

    pool1 = Factories.insert!(:pool, %{name: currency_name1, target: 100, currency: currency1})
    pool2 = Factories.insert!(:pool, %{name: currency_name2, target: 100, currency: currency2})

    row1 = "#{student_id1},#{student1.email},#{student1.user.profile.fullname},#{credits1}\r\n"
    row2 = "#{student_id2},#{student2.email},#{student2.user.profile.fullname},0\r\n"

    assert [
             "studentid,email,name,credits\r\n",
             ^row1,
             ^row2
           ] = Scholar.ExportController.export([student1.user, student2.user], pool1)

    row1 = "#{student_id1},#{student1.email},#{student1.user.profile.fullname},0\r\n"
    row2 = "#{student_id2},#{student2.email},#{student2.user.profile.fullname},#{credits2}\r\n"

    assert [
             "studentid,email,name,credits\r\n",
             ^row1,
             ^row2
           ] = Scholar.ExportController.export([student1.user, student2.user], pool2)
  end

  test "export/2 with 1 surfconext student, 1 test student, 1 pool" do
    currency_name = "vu_sbe_rpr_year1_2022"
    currency = Budget.Factories.create_currency(currency_name, "credits", 0)

    student_id1 = "123"
    student1 = create_surfconext_student(student_id1)
    credits1 = 10

    Factories.insert!(:book_account, %{
      identifier: ["wallet", currency_name, "#{student1.user.id}"],
      balance_credit: credits1,
      balance_debit: 0
    })

    student2 = Factories.insert!(:member, %{student: true})
    credits2 = 5

    Factories.insert!(:book_account, %{
      identifier: ["wallet", currency_name, "#{student2.id}"],
      balance_credit: credits2,
      balance_debit: 0
    })

    pool = Factories.insert!(:pool, %{name: currency_name, target: 100, currency: currency})

    row1 = "#{student_id1},#{student1.email},#{student1.user.profile.fullname},#{credits1}\r\n"
    row2 = ",#{student2.email},#{student2.profile.fullname},#{credits2}\r\n"

    assert [
             "studentid,email,name,credits\r\n",
             ^row1,
             ^row2
           ] = Scholar.ExportController.export([student1.user, student2], pool)
  end

  defp create_surfconext_student(id) do
    Factories.insert!(:surfconext_student, %{
      schac_personal_unique_code: "urn:schac:personalUniqueCode:nl:local:vu.nl:studentid:#{id}"
    })
  end
end
