# frozen_string_literal: true

class ConfirmExistingUsers < ActiveRecord::Migration[8.0]
  def up
    execute "UPDATE users SET confirmed_at = created_at WHERE confirmed_at IS NULL"
  end

  def down
    # no-op: we can't know which users were previously unconfirmed
  end
end
