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
    self.path
  end

  ###  Status report

  # Is the file associated with 'self.path' valid?
  # (Does it exist? Is it a file? Is it readable? ...)
  post 'no reason' do |res| implies(res, self.invalidity_reason == "") end
  post 'reason' do |res| implies(! res, ! self.invalidity_reason.empty?) end
  def is_valid?
    result = true
    self.invalidity_reason = ""
    pth = self.path
    for s in STATUS_SYMBOLS.keys do
      if ! File.send(s, pth) then
        result = false
        self.invalidity_reason = "#{pth} #{STATUS_SYMBOLS[s]}"
        break
      end
    end
    result
  end

  ###  Invariant

  def invariant
    ! self.path.nil? && ! self.invalidity_reason.nil?
  end

  ###  Basic operations

  # "Process" the attachment by executing an external process (i.e.,
  # view-video, edit-file, play-audio, etc.).
  # If 'editing', the external command will be one designated for the
  # purpose of editing the attachment; otherwise, a command designated
  # for viewing will be invoked on the attachment.
  pre '"editing" eixsts' do |editing| ! editing.nil? end
  def process editing
    handler = MediaHandler.new self.path
    if editing then
      handler.edit
    else
      handler.view
    end
  end

  private

  attr_writer :path, :invalidity_reason
  STATUS_SYMBOLS = {
    :exist? => "does not exist",
    :file? => "is not a file",
    :readable? => "is not readable"
  }

  # If specified, default_location is prepended to 'pth' if 'pth' is not an
  # absolute path (does not start with "/").
  # If default_location is empty and 'pth' is not an absolute path, assume
  # 'pth' resides in the current directory.
  pre 'pth valid' do |pth| ! pth.nil? && pth.is_a?(String)  && ! pth.empty? end
  post 'path set' do |r, pth| self.path.include?(pth) end
  post 'invalidity_reason set' do self.invalidity_reason == "" end
  post 'invariant' do invariant end
  def initialize att_pth
    default_location = Configuration.instance.user_path
    if att_pth[0] == "/" then
      self.path = att_pth.clone
    elsif ! default_location.nil? && ! default_location.empty? then
      self.path = "#{default_location}/#{att_pth}"
    else
      self.path = "#{Dir.pwd}/#{att_pth}"
    end
    self.invalidity_reason = ""
    self.invalidity_reason.freeze
    self.path.freeze
  end

end
