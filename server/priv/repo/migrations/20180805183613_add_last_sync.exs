defmodule Ass.Repo.Migrations.AddLastSync do
  use Ecto.Migration

  def change do
    alter table(:records) do
      add :last_sync, :bigint
    end
    create index(:records, [:last_sync])
  end
end
