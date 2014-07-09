class CreateUsers < ActiveRecord::Migration
  
  def change
    create_table :users, force: true, id: false do |t|
      t.integer  :id
      t.string   :email
      t.string   :name
    end

    execute "alter table users add primary key (id);"
  end
  
end
