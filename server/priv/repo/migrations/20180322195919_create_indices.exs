defmodule Ass.Repo.Migrations.CreateIndices do
  use Ecto.Migration

  def change do
    create index(:users, [:email])
    create index(:records, [:last_change])
    create index(:sessions, [:user_id])
    create index(:spaces, [:user_id])
  end
end
