require 'ruby_contracts'

# Wrapper class for external UNIX/Linux commands
class ExternalCommand
  include Contracts::DSL

  public

  # Is 'path' the path of a valid - readable and executable - file?
  def self.valid_executable path
      File.file?(path) && File.readable?(path) && File.executable?(path)
  end

  # Reason that 'path' is not the path of a valid executable
  pre 'path exists' do ! path.nil? && ! path.empty? end
  def self.invalidity_reason path
    result = ""
    reasons = {
      :file?        => "file does not exist.",
      :readable?    => "file is not readable.",
      :executable?  => "file is not executable.",
    }
    reasons.keys.each do |func|
      if ! File.public_send(func, path) then
        result = reasons[func]
        break
      else
      end
    end
    result
  end

  # Execute 'command' (a path to an executable file) in the background via
  # 'spawn', passing it 0 or more arguments. "detach" the resulting process
  # and return its process id (pid).
  def self.execute *command_with_args
    pid = -1
    command  = command_with_args[0]
    if ! valid_executable command then
      raise "#{command} is not valid: #{invalidity_reason command}"
    else
      pid = spawn(*command_with_args)
      Process.detach(pid)
    end
    pid
  end

  private

end
