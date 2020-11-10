defmodule Ass.Repo.Migrations.CreateSets do
  use Ecto.Migration

  def change do
    create table(:sets, primary_key: false) do
      add :key, :string, primary_key: true
      add :user_id, references(:users, type: :id, null: :false)

      timestamps()
    end
  end
end
