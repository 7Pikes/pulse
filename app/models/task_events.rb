module TaskEvents

  def self.refresh
    @@db.close if defined?(@@db)

    @@db = SQLite3::Database.new(':memory:')
    @@db.busy_timeout = 10000

    @@db.execute(<<-'EOS')
      CREATE TABLE events (
        name varchar(255),
        user_name varchar(255),
        column_name varchar(255),
        task_title varchar(255),
        created_at integer
      )
    EOS
  end

  def self.db
    @@db
  end

  def self.with_column_names(row)
    {
      "name" => row[0],
      "user_name" => row[1],
      "column_name" => row[2],
      "task_title" => row[3],
      "created_at" => row[4]
    }
  end

  # refresh
end
