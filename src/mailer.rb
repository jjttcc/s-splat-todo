# Objects that extract needed fields (subject, addresses, body, ...) from
# an Email in order to send the resulting email message.
class Mailer

  attr_reader :templated_email_command

  public

  def send email
    subject, addresses, body = email.subject, email.to_addrs, email.body
#puts "subject: #{subject}, addresses: #{addresses}, body: #{body}"
  end

  private

  def initialize config
    @templated_email_command = config.templated_email_command
#puts "templated_email_command: #{templated_email_command}"
  end

  def message_components email
  end

end
