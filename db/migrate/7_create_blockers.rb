class CreateBlockers < ActiveRecord::Migration
  
  def change
    create_table :blockers, force: true do |t|
      t.integer    :task_id, null: false
      t.text       :message
      t.boolean    :active
      t.datetime   :created
      t.datetime   :updated                   # field to determine what was the last day of life
    end
  end
  
end
