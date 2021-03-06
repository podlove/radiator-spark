defmodule Radiator.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people) do
      add :name, :text
      add :display_name, :text, null: false
      add :nick, :text
      add :email, :text
      add :image, :text
      add :link, :text

      add :user_id, references(:auth_users, on_delete: :nothing)
      add :network_id, references(:networks, on_delete: :nothing)

      timestamps()
    end
  end
end
