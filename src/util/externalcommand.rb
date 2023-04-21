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

  # Execute 'command_with_args' (a path to an executable file, with 0
  # or more arguments) in the background via 'spawn'.
  # "detach" the resulting process and return its process id (pid).
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

  # Execute 'command_with_args' (a path to an executable file, with 0 or
  # more arguments) and wait for it to finish.
  def self.execute_and_block *command_with_args
    pid = -1
    command  = command_with_args[0]
    if ! valid_executable command then
      raise "#{command} is not valid: #{invalidity_reason command}"
    else
      pid = spawn(*command_with_args)
      Process.wait(pid)
    end
    pid
  end

  # Execute 'command_with_args' (a path to an executable file, with 0 or
  # more arguments), wait for it to finish, and return the output/stdout as
  # an array - one element per line of output.
  post 'result is array' do |result| ! result.nil? && result.is_a?(Array) end
  def self.execute_with_output *command_with_args
    result = []
    command  = command_with_args[0]
    if ! valid_executable command then
      raise "#{command} is not valid: #{invalidity_reason command}"
    else
      io = IO.popen(command_with_args)
      result = io.readlines(chomp: true)
      io.close
    end
    result
  end

  private

end
