class ProcessImageJob < ApplicationJob
  queue_as :default

  def perform(attachment_id)
    attachment = ActiveStorage::Attachment.find(attachment_id)
    attachment.variant(resize: "800x600").processed
  end
end
