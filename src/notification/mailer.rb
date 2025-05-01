require 'spectools'

# Objects that extract needed fields (subject, addresses, body, ...) from
# an Email in order to send the resulting email message.
class Mailer
  include SpecTools

  attr_reader :templated_email_command

  public

  def send_message email
    subject, addresses, body = email.subject, email.to_addrs, email.body
    if ! templated_email_command.nil? && ! templated_email_command.empty? then
      command = email_command(subject, addresses)
      exec_cmd command, body
    else
      $log.warn "'#{Configuration::EMAIL_TEMPLATE_TAG}' not set"
    end
  end

  private

  def initialize config
    @templated_email_command = config.templated_email_command
    @configuration = config
  end

  def email_command subj, addrs
    result = []
    work_array = templated_email_command.split
    work_array.each do |word|
      if word.sub!(SUBJECT_TEMPLATE_PTRN, "'#{subj}'") then
        result << word
      elsif word =~ ADDRS_TEMPLATE_PTRN then
        result.concat(addrs)
      else  # No match, so just append 'word' (command or simple argument):
        result << word
      end
    end
    result
  end

  # Send the mail using 'mail_cmd' (an array suitable for use in IO.popen,
  # which is expected to contain the subject) with body: 'body'.
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
