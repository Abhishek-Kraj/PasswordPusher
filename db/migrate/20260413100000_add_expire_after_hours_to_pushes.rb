# frozen_string_literal: true

class AddExpireAfterHoursToPushes < ActiveRecord::Migration[8.1]
  def change
    add_column :pushes, :expire_after_hours, :integer, default: 0
  end
end
