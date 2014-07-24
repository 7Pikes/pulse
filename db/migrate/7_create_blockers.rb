class CreateBlockers < ActiveRecord::Migration
  
  def change
    create_table :blockers, force: true do |t|
      t.text       :message
      t.datetime   :created
    end
  end
  
end
