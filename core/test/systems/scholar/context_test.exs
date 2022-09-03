defmodule Systems.Scholar.ContextTest do
  use Core.DataCase

  alias Systems.{
    Scholar,
    Budget,
    Pool,
    Org,
    Bookkeeping
  }

  test "handle_features_updated/3 succeeded" do
    student = Factories.insert!(:member, %{student: true})

    last_year = "course_year1_2000"
    current_year = "course_year1_2001"

    last_year_currency = Budget.Factories.create_currency(last_year, "credits", 0)
    current_year_currency = Budget.Factories.create_currency(current_year, "credits", 0)

    last_year_wallet = ["wallet", last_year, "#{student.id}"]
    current_year_wallet = ["wallet", current_year, "#{student.id}"]

    Factories.insert!(:pool, %{name: last_year, target: 100, currency: last_year_currency})
    Factories.insert!(:pool, %{name: current_year, target: 100, currency: current_year_currency})

    Core.Factories.insert!(:book_account, %{
      identifier: last_year_wallet,
      balance_credit: 99,
      balance_debit: 0
    })

    Core.Factories.insert!(:book_account, %{
      identifier: current_year_wallet,
      balance_credit: 0,
      balance_debit: 0
    })

    class_2001 =
      Core.Factories.insert!(:org_node, %{
        type: :scholar_class,
        identifier: ["class", ":year1", ":2001"]
      })

    course_2001 =
      Core.Factories.insert!(:org_node, %{
        type: :scholar_course,
        identifier: ["course", ":year1", ":2001"]
      })

    Core.Factories.insert!(:org_link, %{
      from: class_2001,
      to: course_2001
    })

    Scholar.Context.handle_features_updated(student, [], [:class_year1_2001])

    assert %{
             balance_credit: 99,
             balance_debit: 99
           } = Bookkeeping.Context.get_account!(last_year_wallet)

    assert %{
             balance_credit: 99,
             balance_debit: 0
           } = Bookkeeping.Context.get_account!(current_year_wallet)
  end

  test "handle_features_updated/3 skipped: target already met" do
    student = Factories.insert!(:member, %{student: true})

    last_year = "course_year1_2000"
    current_year = "course_year1_2001"

    last_year_currency = Budget.Factories.create_currency(last_year, "credits", 0)
    current_year_currency = Budget.Factories.create_currency(current_year, "credits", 0)

    last_year_wallet = ["wallet", last_year, "#{student.id}"]
    current_year_wallet = ["wallet", current_year, "#{student.id}"]

    Factories.insert!(:pool, %{name: last_year, target: 100, currency: last_year_currency})
    Factories.insert!(:pool, %{name: current_year, target: 100, currency: current_year_currency})

    Core.Factories.insert!(:book_account, %{
      identifier: last_year_wallet,
      balance_credit: 100,
      balance_debit: 0
    })

    Core.Factories.insert!(:book_account, %{
      identifier: current_year_wallet,
      balance_credit: 0,
      balance_debit: 0
    })

    class_2001 =
      Core.Factories.insert!(:org_node, %{
        type: :scholar_class,
        identifier: ["class", ":year1", ":2001"]
      })

    course_2001 =
      Core.Factories.insert!(:org_node, %{
        type: :scholar_course,
        identifier: ["course", ":year1", ":2001"]
      })

    Core.Factories.insert!(:org_link, %{
      from: class_2001,
      to: course_2001
    })

    Scholar.Context.handle_features_updated(student, [], [:class_year1_2001])

    assert %{
             balance_credit: 100,
             balance_debit: 0
           } = Bookkeeping.Context.get_account!(last_year_wallet)

    assert %{
             balance_credit: 0,
             balance_debit: 0
           } = Bookkeeping.Context.get_account!(current_year_wallet)
  end

  test "generate_vu/5" do
    academic_year = 2024
    study_year = 1
    Scholar.Context.generate_vu(academic_year, study_year, "1st", "1e", 100)

    name = "vu_sbe_rpr_year#{study_year}_#{academic_year}"
    identifier = ["vu", "sbe", "rpr", ":year#{study_year}", ":#{academic_year}"]

    assert %{
             name: ^name,
             decimal_scale: 0,
             label_bundle: %{
               items: [
                 %{
                   locale: "en",
                   text: "%{amount} credit",
                   text_plural: "%{amount} credits"
                 }
               ]
             }
           } = Budget.Context.get_currency_by_name(name, label_bundle: [:items])

    assert %{
             name: ^name,
             currency: %{
               name: ^name
             },
             fund: %{
               balance_credit: 0,
               balance_debit: 0,
               identifier: ["fund", ^name]
             },
             reserve: %{
               balance_credit: 0,
               balance_debit: 0,
               identifier: ["reserve", ^name]
             },
             rewards: []
           } = Budget.Context.get_by_name(name, [:fund, :reserve, :rewards, :currency])

    assert %{
             name: ^name,
             currency: %{
               name: ^name
             },
             org: %{
               identifier: ^identifier,
               type: :scholar_course
             },
             target: 100
           } = Pool.Context.get_by_name(name, [:org, :currency])

    assert %{
             type: :scholar_course,
             identifier: ^identifier,
             full_name_bundle: %{
               items: [
                 %{
                   locale: "en",
                   text: "RPR 1st year (2024)",
                   text_plural: nil
                 },
                 %{
                   locale: "nl",
                   text: "RPR 1e jaar (2024)",
                   text_plural: nil
                 }
               ]
             },
             short_name_bundle: %{
               items: [
                 %{
                   locale: "en",
                   text: "RPR 1st year",
                   text_plural: nil
                 },
                 %{
                   locale: "nl",
                   text: "RPR 1e jaar",
                   text_plural: nil
                 }
               ]
             },
             links: [],
             users: []
           } =
             Org.Context.get_node(identifier, [
               :users,
               :links,
               short_name_bundle: [:items],
               full_name_bundle: [:items]
             ])

    assert %{
             type: :scholar_class,
             identifier: ["vu", "sbe", "bk", ":year1", ":2024"],
             full_name_bundle: %{
               items: [
                 %{
                   locale: "en",
                   text: "BK 1st year (2024)",
                   text_plural: nil
                 },
                 %{
                   locale: "nl",
                   text: "BK 1e jaar (2024)",
                   text_plural: nil
                 }
               ]
             },
             short_name_bundle: %{
               items: [
                 %{
                   locale: "en",
                   text: "BK 1st year",
                   text_plural: nil
                 },
                 %{
                   locale: "nl",
                   text: "BK 1e jaar",
                   text_plural: nil
                 }
               ]
             },
             links: [
               %{
                 type: :scholar_course,
                 identifier: ["vu", "sbe", "rpr", ":year1", ":2024"]
               }
             ],
             users: []
           } =
             Org.Context.get_node(["vu", "sbe", "bk", ":year1", ":2024"], [
               :users,
               :links,
               short_name_bundle: [:items],
               full_name_bundle: [:items]
             ])

    assert %{
             type: :scholar_class,
             identifier: ["vu", "sbe", "iba", ":year1", ":2024"],
             full_name_bundle: %{
               items: [
                 %{
                   locale: "en",
                   text: "IBA 1st year (2024)",
                   text_plural: nil
                 },
                 %{
                   locale: "nl",
                   text: "IBA 1e jaar (2024)",
                   text_plural: nil
                 }
               ]
             },
             short_name_bundle: %{
               items: [
                 %{
                   locale: "en",
                   text: "IBA 1st year",
                   text_plural: nil
                 },
                 %{
                   locale: "nl",
                   text: "IBA 1e jaar",
                   text_plural: nil
                 }
               ]
             },
             links: [
               %{
                 type: :scholar_course,
                 identifier: ["vu", "sbe", "rpr", ":year1", ":2024"]
               }
             ],
             users: []
           } =
             Org.Context.get_node(["vu", "sbe", "iba", ":year1", ":2024"], [
               :users,
               :links,
               short_name_bundle: [:items],
               full_name_bundle: [:items]
             ])
  end
end
