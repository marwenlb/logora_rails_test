class ModeratedModel < ApplicationRecord
    include Moderable
  
    def change
      create_table :moderated_models do |t|
        t.text :content
        t.boolean :is_accepted
        t.text :language
        t.timestamps
      end
    end
  end