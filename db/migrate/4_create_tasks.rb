class CreateTasks < ActiveRecord::Migration
  
  def change
    create_table :tasks, force: true, id: false do |t|
      t.integer    :id
      t.text       :title
      t.text       :description
      t.text       :global_in_context_url
      t.integer    :phase_id
      t.integer    :user_id
      t.integer    :watcher_id
      t.boolean    :blocked
      t.boolean    :ready_to_pull
      t.datetime   :moved_at
    end

    execute "alter table tasks add primary key (id);"
  end
  
end
