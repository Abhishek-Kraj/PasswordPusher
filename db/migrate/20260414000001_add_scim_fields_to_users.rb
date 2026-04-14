# frozen_string_literal: true

class AddScimFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :external_id, :string
    add_column :users, :active, :boolean, default: true
    add_column :users, :given_name, :string
    add_column :users, :family_name, :string
    add_index :users, :external_id, unique: true
  end
end
