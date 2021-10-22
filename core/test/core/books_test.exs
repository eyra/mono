defmodule Core.BooksTest do
  use Core.DataCase, async: true
  alias Core.Books

  describe "enter/1" do
    test "enter single booking" do
      amount = :rand.uniform(10_000)

      :ok =
        Books.enter(%{
          idempotence_key: Faker.String.base64(),
          journal_message: "Bank transaction: 123, received: 123,45 for money box: 89",
          lines: [
            %{
              book: :bank,
              debit: amount
            },
            %{
              book: {:money_box_budget, 89},
              credit: amount
            }
          ]
        })

      assert %{debit: ^amount} = Books.balance(:bank)
      assert %{credit: ^amount} = Books.balance({:money_box_budget, 89})
    end

    test "enter multiple bookings partialy, for the same books" do
      money_box_one = :rand.uniform(100)
      money_box_two = :rand.uniform(100) + 200
      first_amount = :rand.uniform(10_000)
      second_amount = :rand.uniform(10_000)

      :ok =
        Books.enter(%{
          idempotence_key: Faker.String.base64(),
          journal_message: "Bank transaction",
          lines: [
            %{
              book: :bank,
              debit: first_amount
            },
            %{
              book: {:money_box_budget, money_box_one},
              credit: first_amount
            }
          ]
        })

      :ok =
        Books.enter(%{
          idempotence_key: Faker.String.base64(),
          journal_message: "Bank transaction",
          lines: [
            %{
              book: :bank,
              debit: second_amount
            },
            %{
              book: {:money_box_budget, money_box_two},
              credit: second_amount
            }
          ]
        })

      expected_bank_amount = first_amount + second_amount
      assert %{debit: ^expected_bank_amount, credit: 0} = Books.balance(:bank)
      assert %{credit: ^first_amount} = Books.balance({:money_box_budget, money_box_one})
      assert %{credit: ^second_amount} = Books.balance({:money_box_budget, money_box_two})
    end

    for {debit, credit} <- [{1, 2}, {2, 1}] do
      test "require lines to balance: #{debit} v.s. #{credit}" do
        result =
          Books.enter(%{
            idempotence_key: Faker.String.base64(),
            journal_message: "",
            lines: [
              %{
                book: :bank,
                debit: unquote(debit)
              },
              %{
                book: {:money_box_budget, 1},
                credit: unquote(credit)
              }
            ]
          })

        assert result == {:error, :unbalanced_lines}
      end
    end

    test "require lines to have either debit or credit, not both" do
      result =
        Books.enter(%{
          idempotence_key: Faker.String.base64(),
          journal_message: "",
          lines: [
            %{
              book: :bank,
              debit: 1,
              credit: 1
            },
            %{
              book: {:money_box_budget, 1},
              credit: 0
            }
          ]
        })

      assert result == {:error, :entry_with_both_debit_and_credit}
    end

    test "require lines to have a unique idempotence key" do
      :ok =
        Books.enter(%{
          idempotence_key: "test",
          journal_message: "Testing",
          lines: [
            %{
              book: :bank,
              debit: 1
            },
            %{
              book: {:money_box_budget, 1},
              credit: 1
            }
          ]
        })

      result =
        Books.enter(%{
          idempotence_key: "test",
          journal_message: "Testing 2",
          lines: [
            %{
              book: :bank,
              debit: 1
            },
            %{
              book: {:money_box_budget, 1},
              credit: 1
            }
          ]
        })

      assert result == {:error, :idempotence_key_conflict}
    end
  end

  describe "list_lines/1" do
    test "listing of an unknown book returns empty list" do
      assert Books.list_entries(:bank) == []
    end

    test "entries have the lines" do
      :ok =
        Books.enter(%{
          idempotence_key: "a",
          journal_message: "Bank transaction: 123, received: 123,45 for money box: 89",
          lines: [
            %{
              book: :bank,
              debit: 1
            },
            %{
              book: {:money_box_budget, 1},
              credit: 1
            }
          ]
        })

      :ok =
        Books.enter(%{
          idempotence_key: "b",
          journal_message: "Bank transaction: 123, received: 123,45 for money box: 89",
          lines: [
            %{
              book: :bank,
              debit: 2
            },
            %{
              book: {:money_box_budget, 2},
              credit: 2
            }
          ]
        })

      assert Books.list_entries(:bank) == [
               %{
                 idempotence_key: "a",
                 journal_message: "Bank transaction: 123, received: 123,45 for money box: 89",
                 lines: [%{credit: nil, debit: 1}]
               },
               %{
                 idempotence_key: "b",
                 journal_message: "Bank transaction: 123, received: 123,45 for money box: 89",
                 lines: [%{credit: nil, debit: 2}]
               }
             ]
    end
  end
end
