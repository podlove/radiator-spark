defmodule Radiator.Repo.Migrations.CreateDownloads do
  use Ecto.Migration

  def change do
    create table(:downloads) do
      add :request_id, :string
      add :accessed_at, :utc_datetime
      add :httprange, :string
      add :context, :string
      add :referer, :text

      add :user_agent, :text
      add :client_name, :string
      add :client_type, :string
      add :os_name, :string
      add :device_type, :string
      add :device_model, :string

      add :hours_since_published, :integer

      add :network_id, references(:networks, on_delete: :nothing)
      add :podcast_id, references(:podcasts, on_delete: :nothing)
      add :episode_id, references(:episodes, on_delete: :nothing)
      add :audio_publication_id, references(:audio_publications, on_delete: :nothing)
      add :audio_id, references(:audios, on_delete: :nothing)
      add :file_id, references(:audio_files, on_delete: :nothing)

      timestamps()
    end

    create index(:downloads, [:network_id])
    create index(:downloads, [:podcast_id])
    create index(:downloads, [:episode_id])
    create index(:downloads, [:audio_publication_id])

    create unique_index(
             :downloads,
             [:file_id, :request_id, "(accessed_at::date)"],
             name: :downloads_daily_unique_request_index
           )
  end
end
