defmodule Ass.Repo.Migrations.CreateRecords do
  use Ecto.Migration

  def change do
    create table(:records, primary_key: false) do
      add :key, :string, primary_key: true
      add :set_key, references(:sets, type: :string, null: :false, column: :key), primary_key: true
      add :last_change, :bigint
      add :data, :map

      timestamps()
    end
  end
end