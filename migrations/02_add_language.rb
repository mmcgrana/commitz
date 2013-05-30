Sequel.migration do
  change do
    add_column :commits, :language, "text"
  end
end
