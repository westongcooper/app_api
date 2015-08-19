Sequel.migration do
  up do
    create_table(:appts) do
      primary_key :id
      timestamp :start_time, null: false
      timestamp :end_time, null: false
      String :first_name, :null=>false
      String :last_name, :null=>false
      String :comments
    end
  end

  down do
    drop_table(:appts)
  end
end