# Error-logging interface
module ErrorLog
  include Contracts::DSL

  public  ###  Basic operations

  # Log 'msg' as an error.
  def error(msg)
    send(:error, msg)
  end

  # Log 'msg' as a warning message.
  def warn(msg)
    send(:warn, msg)
  end

  # Log 'msg' as debugging message.
  def debug(msg)
    send(:debug, msg)
  end

  # Log 'msg' as informational message.
  def info(msg)
    send(:info, msg)
  end

  # Log 'msg' as an "unknown" message.
  def unknown(msg)
    send(:unknown, msg)
  end

  # Log 'msg' as a test message.
  def test(msg)
    send(:test, msg)
  end

  protected

  pre :args_exist do |msg, tag| ! (msg.nil? || tag.nil?) end
  def send(tag, msg)
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

end
