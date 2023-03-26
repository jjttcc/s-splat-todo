require 'forwardable'
require 'ruby_contracts'

# Wrapper class for the UNIX/Linux 'file' command
class FileCommand
  include Contracts::DSL
  extend Forwardable

  public

  # Exeucte the 'file' command, with the '--mime' option, and return the
  # result.
  pre  'path exists' do |path| ! path.nil? && ! path.empty? end
  post 'result exists' do |result| ! result.nil? && ! result.empty? end
  def self.mime_type path
    if @@file_command_path.nil? then
      set_command_path
    end
    cmd_components = [@@file_command_path] + mime_file_command_args + [path]
    cmd = IO.popen(cmd_components)
    if ! cmd.eof? then
      result = cmd.readline.chomp
    else
      result = ""
    end
    result
  end

  # Exeucte the 'file' command, WITHOUT the '--mime' option, and return the
  # result.
  pre  'path exists' do |path| ! path.nil? && ! path.empty? end
  post 'result exists' do |result| ! result.nil? && ! result.empty? end
  def self.traditional_type path
    if @@file_command_path.nil? then
      set_command_path
    end
    cmd_components = [@@file_command_path] + trad_file_command_args + [path]
    cmd = IO.popen(cmd_components)
    if ! cmd.eof? then
      result = cmd.readline.chomp
    else
      result = ""
    end
    result
  end

  public

  def self.file_command_path
    @@file_command_path
  end

  private

  def_delegator :FileCommand, :mime_type
  def_delegator :FileCommand, :traditional_type
  def_delegator :FileCommand, :mime_file_command_args
  def_delegator :FileCommand, :trad_file_command_args
  def_delegator :FileCommand, :file_command_path

  def initialize binpath = nil
    set_command_path binpath
  end

  ###  Implementation - class methods

  def self.mime_file_command_args
    ['--brief', '--mime', '-L']
  end

  def self.trad_file_command_args
    ['--brief', '-L']
  end

  ###  Implementation

  # Set '@@file_command_path' to a valid file-command location.
  def set_command_path binpath = nil
    if binpath.nil? then
      @@file_command_path = '/bin/file'
      if ! valid_executable @@file_command_path then
        @@file_command_path = '/usr/bin/file'
      end
    else
      @@file_command_path = binpath
    end
    if ! valid_executable @@file_command_path then
      raise "#{binpath} is invalid: #{invalidity_reason binpath}"
    end
  end

  # Is 'path' the path of a valid - readable and executable - file?
  def valid_executable path
      File.file?(path) && File.readable?(path) && File.executable?(path)
  end

  # Reason that 'path' is not the path of a valid executable
  pre 'path is not valid' do ! valid_executable path end
  def invalidity_reason path
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

end
