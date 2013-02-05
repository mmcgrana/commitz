Sequel.migration do
  change do
    create_table :commits do
      primary_key :id

      column :repo,       "text"
      column :sha,        "text"
      column :additions,  "integer"
      column :deletions,  "integer"
      column :total,      "integer"
      column :email,      "text"
      column :date,       DateTime
      column :message,    "text"
    end
  end
end
