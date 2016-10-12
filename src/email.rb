# Self-sending (with the help of a "mailer") emails
class Email

  attr_reader :to_addrs, :cc_addrs, :bcc_addrs, :subject, :body

  public

  def send mailer
    mailer.send self
  end

  private

  def initialize(to_addrs, subject, body)
#puts "[Email] toadd, subj, body: #{to_addrs}, #{subject}, #{body}"
    @to_addrs = to_addrs; @subject = subject; @body = body
  end

end
