defmodule Radiator.Repo.Migrations.CreateEpisodes do
  use Ecto.Migration

  def change do
    create table(:episodes) do
      add :guid, :string
      add :short_id, :string
      add :title, :string
      add :subtitle, :string
      add :summary, :text
      add :summary_html, :text
      add :summary_source, :text

      add :number, :integer
      add :published_at, :utc_datetime

      add :slug, :string

      add :podcast_id, references(:podcasts, on_delete: :delete_all)
      add :audio_id, references(:audios, on_delete: :nilify_all)

      timestamps()
    end

    create index(:episodes, [:guid])
    create index(:episodes, [:podcast_id])
    create index(:episodes, ["lower(short_id)"])
    create index(:episodes, ["lower(slug)", :podcast_id], unique: true)
  end
end
