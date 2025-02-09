Code.require_file "support/schemas.exs", __DIR__

defmodule Sqlite.Ecto3.RepoTest do
  use Ecto.Integration.Case, async: Application.get_env(:ecto, :async_integration_tests, true)

  alias Ecto.Integration.TestRepo
  import Ecto.Query

  alias Sqlite.Ecto3.Test.MiscTypes

  test "preserves time with microseconds" do
    TestRepo.insert!(%MiscTypes{name: "hello", start_time: ~T(09:33:51), cost: 1})
    assert [%MiscTypes{name: "hello", start_time: ~T(09:33:51)}] =
      TestRepo.all from mt in MiscTypes
  end

  test "handles time with milliseconds" do
    # Looks like Ecto doesn't provide a way for adapter to see the subsecond
    # precision of timestamps so we always fill out the time with zeros.
    TestRepo.insert!(%MiscTypes{name: "hello", start_time: ~T(09:33:51), cost: 1})
    assert [%MiscTypes{name: "hello", start_time: ~T(09:33:51)}] =
      TestRepo.all from mt in MiscTypes
  end

  test "preserves decimal without precision" do
    TestRepo.insert!(%MiscTypes{name: "hello", start_time: ~T(09:33:51), cost: 3.1415})
    pi_ish = Decimal.from_float(3.1415)
    assert [%MiscTypes{name: "hello", cost: ^pi_ish}] =
      TestRepo.all from mt in MiscTypes
  end

  test "insert! with on_conflict replace_all" do
    TestRepo.insert!(
      %MiscTypes{id: 1, name: "foo", start_time: ~T(01:01:01), cost: 3}
    )

    TestRepo.insert!(
      %MiscTypes{id: 1, name: "hello", start_time: ~T(09:33:51), cost: 3.1415},
      [
        on_conflict: :replace_all,
        conflict_target: [:id],
      ]
    )

    pi_ish = Decimal.from_float(3.1415)
    assert [%MiscTypes{name: "hello", cost: ^pi_ish}] =
      TestRepo.all from mt in MiscTypes
  end

  test "insert! with on_conflict replace_all_except_primary_key" do
    assert_raise ArgumentError, ~r/^Upsert in SQLite requires :conflict_target$/, fn ->
      TestRepo.insert!(
        %MiscTypes{id: 1, name: "hello", start_time: ~T(09:33:51), cost: 3.1415},
        [
          on_conflict: :replace_all_except_primary_key
        ]
      )
    end
  end
end
