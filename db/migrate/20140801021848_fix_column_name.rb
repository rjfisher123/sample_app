class FixColumnName < ActiveRecord::Migration
  def change
  	rename_column :microposts, :in_reply_to_id, :to_id
  end
end
