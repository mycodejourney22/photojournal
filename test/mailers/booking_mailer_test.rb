require "test_helper"

class BookingMailerTest < ActionMailer::TestCase
  test "reminder_email" do
    mail = BookingMailer.reminder_email
    assert_equal "Reminder email", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
