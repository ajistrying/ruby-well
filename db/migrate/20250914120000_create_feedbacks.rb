class CreateFeedbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :feedbacks do |t|
      t.string :feedback_type, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.string :email
      t.string :feed_url
      t.string :status, default: 'pending'
      
      t.timestamps
    end
    
    add_index :feedbacks, :feedback_type
    add_index :feedbacks, :status
    add_index :feedbacks, :created_at
  end
end