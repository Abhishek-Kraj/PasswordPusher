class FixActiveStorageBlobIdType < ActiveRecord::Migration[8.0]
  def up
    return unless connection.adapter_name.downcase.include?("mysql") || connection.adapter_name.downcase.include?("mariadb")

    if column_for(:active_storage_attachments, :blob_id).sql_type.include?("int(11)")
      remove_foreign_key :active_storage_attachments, :active_storage_blobs, column: :blob_id, if_exists: true
      change_column :active_storage_attachments, :blob_id, :bigint, null: false
      add_foreign_key :active_storage_attachments, :active_storage_blobs, column: :blob_id
    end

    if column_for(:active_storage_variant_records, :blob_id).sql_type.include?("int(11)")
      remove_foreign_key :active_storage_variant_records, :active_storage_blobs, column: :blob_id, if_exists: true
      change_column :active_storage_variant_records, :blob_id, :bigint, null: false
      add_foreign_key :active_storage_variant_records, :active_storage_blobs, column: :blob_id
    end
  end

  def down
    # No-op: reverting to int(11) would break the foreign key again
  end

  private

  def column_for(table, column_name)
    connection.columns(table).find { |c| c.name == column_name.to_s }
  end
end
