require 'ruby_contracts'
require 'filecommand'
require 'mediahandler'

# Abstraction for file attachments (whose 'path' attribute is immutable)
# that can be added to an (STodoTarget) item
class Attachment
  include Contracts::DSL

  public

  ###  Access

  attr_reader :path, :invalidity_reason

  def to_s
    path
  end

  ###  Status report

  # Is the file associated with 'self.path' valid?
  # (Does it exist? Is it a file? Is it readable? ...)
  # If path_override is specified (not nil, not empty), then use this value
  # as the path to check instead of 'self.path'.
  post 'no reason' do |res| implies(res, invalidity_reason == "") end
  post 'reason' do |res| implies(! res, ! invalidity_reason.empty?) end
  def is_valid?(path_override = nil)
    result = true
    tgt_path =
      (! path_override.nil? && ! path_override.empty?)?  path_override: path
    self.invalidity_reason = ""
    for s in VALID_STATUS_SYMBOLS.keys do
      if ! File.send(s, tgt_path) then
        result = false
        self.invalidity_reason = "#{tgt_path} #{VALID_STATUS_SYMBOLS[s]}"
        break
      end
    end
    result
  end

  def is_directory?
    File.directory?(path)
  end

  ###  Invariant

  def invariant
    ! path.nil? && ! invalidity_reason.nil?
  end

  ###  Basic operations

  # "Process" the attachment by executing an external process (i.e.,
  # view-video, edit-file, play-audio, etc.).
  # If 'editing', the external command will be one designated for the
  # purpose of editing the attachment; otherwise, a command designated
  # for viewing will be invoked on the attachment.
  pre '"editing" eixsts' do |editing| ! editing.nil? end
  def process editing
    handler = MediaHandler.new path
    if editing then
      handler.edit
    else
      handler.view
    end
  end

  private

  attr_writer :path, :invalidity_reason
  VALID_STATUS_SYMBOLS = {
    :exist? => "does not exist",
    :file? => "is not a file",
    :readable? => "is not readable"
  }

  # If 'fname' is an absolute path (starts with "/"), use its value as the
  # new Attachment's path. Otherwise, assume it is a relative path and use
  # the following algorithm to determine the Attachment's path:
  #  if Configuration.instance.user_path is not empty then
  #    self.path = "#{Configuration.instance.user_path}/#{fname}"
  #  else
  #    self.path = "#{Dir.pwd}/#{fname}"
  #  end
  #  if !is_valid?(self.path)&&is_valid?("#{alternate_location}/#{fname}") then
  #    self.path = "#{alternate_location}/#{fname}"
  #  end
  pre 'fname valid' do |fname|
    ! fname.nil? && fname.is_a?(String)  && ! fname.empty?
  end
  post 'path set' do |r, fname| path.include?(fname) end
  post 'invalidity_reason set' do invalidity_reason == "" end
  post 'invariant' do invariant end
  def initialize fname, alternate_location = nil
    default_location = Configuration.instance.user_path
    if fname[0] == "/" then
      self.path = fname.clone
    elsif ! default_location.nil? && ! default_location.empty? then
      self.path = "#{default_location}/#{fname}"
    else
      self.path = "#{Dir.pwd}/#{fname}"
    end
    if ! is_valid?(self.path) then
      path_candidate = "#{alternate_location}/#{fname}"
      if is_valid?(path_candidate) then
        self.path = path_candidate
      end
    end
    self.invalidity_reason = ""
    self.invalidity_reason.freeze
    self.path.freeze
  end

end
