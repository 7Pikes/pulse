class CreateDeadlines < ActiveRecord::Migration
  
  def change
    create_table :deadlines, force: true do |t|
      t.integer    :task_id
      t.datetime   :deadline
    end

    execute "alter table deadlines add unique key (task_id, deadline);"
  end
  
end
