class CreateTaskLifecycles < ActiveRecord::Migration
  
  def change
    create_table :task_lifecycles, force: true do |t|
      t.integer    :task_id
      t.integer    :programming
      t.integer    :reviewing
      t.integer    :testing
    end

    execute "alter table task_lifecycles add unique key (task_id);"
  end
  
end
