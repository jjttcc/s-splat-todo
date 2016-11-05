# Objects that extract needed fields (subject, addresses, body, ...) from
# an Email in order to send the resulting email message.
class Mailer
  include SpecTools

  attr_reader :templated_email_command

  public

  def send email
    subject, addresses, body = email.subject, email.to_addrs, email.body
    command = email_command(subject, addresses)
    exec_cmd command, body
  end

  private

  def initialize config
    @templated_email_command = config.templated_email_command
    @configuration = config
  end

  def email_command subj, addrs
    result = templated_email_command.clone
    result.sub!(SUBJECT_TEMPLATE_PTRN, "'#{subj}'")
    addr_str = ""
    addrs.each do |a| addr_str += "#{a} " end
    result.sub!(ADDRS_TEMPLATE_PTRN, addr_str)
  end

  def exec_cmd mail_cmd, body
    if @configuration.test_run? then
      $log.debug "#{self.class} Pretending to pipe to #{mail_cmd}"
    else
      pipe = IO.popen(mail_cmd, mode='w')
      pipe.write(body)
      pipe.close
    end
  end

end
