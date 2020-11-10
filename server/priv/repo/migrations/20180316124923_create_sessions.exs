defmodule Ass.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions, primary_key: false) do
      add :token, :string, primary_key: true
      add :user_id, references(:users, type: :id, null: :false)

      timestamps()
    end
  end
end
