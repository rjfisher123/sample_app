class AddIndexToMicropostUserIdToId < ActiveRecord::Migration
  def change
  	    add_index :microposts, [:user_id, :to_id]
  end
end
