class AddAttachmentConfiguration < ActiveRecord::Migration
  def self.up
    add_column :global_configurations, :maximum_attachment_size, :integer, :default => 1024 * 1024 # 1 MiB
    add_column :global_configurations, :allowed_attachment_mime_types, :string, :default => "text/plain, image/jpeg, image/png, application/x-gzip, application/zip"
  end

  def self.down
    remove_column :global_configurations, :maximum_attachment_size
    remove_column :global_configurations, :allowed_attachment_mime_types
  end
end
