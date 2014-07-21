class CreateBlockedByDays < ActiveRecord::Migration
  
  def change
    create_table :blocked_by_days, force: true do |t|
      t.integer    :count
      t.datetime   :day
    end

    execute "alter table blocked_by_days add unique key (day);"
  end
  
end
