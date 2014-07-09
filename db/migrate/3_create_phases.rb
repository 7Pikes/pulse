class CreatePhases < ActiveRecord::Migration
  
  def change
    create_table :phases, force: true, id: false do |t|
      t.integer  :id
      t.string   :name
      t.integer  :position
    end

    execute "alter table phases add primary key (id);"
  end
  
end
