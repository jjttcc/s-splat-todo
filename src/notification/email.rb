# Self-sending (with the help of a "mailer") emails
class Email

  attr_reader :to_addrs, :subject, :body, :mailer

  public

  # Send the email
  def send_message source
    @to_addrs = source.notification_email_addrs
    @subject = source.notification_subject
    @body = source.full_notification_message
    mailer.send_message self
  end

  private

  def initialize(mailer)
    @mailer = mailer
  end

end
