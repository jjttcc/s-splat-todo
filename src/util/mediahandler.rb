require 'ruby_contracts'
require 'filetypetools'

# Abstraction for handlers of files of different media types, for "handling" -
# viewing (video), playing (audio), viewing (document), editing (document),
# processing (e.g., executing a program or script), etc. - of the files
class MediaHandler
  include Contracts::DSL
  include FileTypeTools

  public

  ###  Access

  attr_reader :path, :config

  ###  Basic operations

  # Invoke the appropriate command to edit the file at self.path.
  def edit
    type = filecommand.mime_type self.path
    stodo_type = file_type_for type
    editor = config.media_editor_for stodo_type
#!!!!Need an 'execute' method    editor.execute self.path
$log.warn "I (#{self.class}) will try to edit #{self.path} for:"
$log.warn "type: #{type}, stodo-type: #{stodo_type}, editor: #{editor}"
  end

  # Invoke the appropriate command to view the file at self.path.
  def view
    type = filecommand.mime_type self.path
    stodo_type = file_type_for type
    viewer = config.media_viewer_for stodo_type
$log.warn "I (#{self.class}) will try to view #{self.path} for:"
$log.warn "type: #{type}, stodo-type: #{stodo_type}, viewer: #{viewer}"
  end

  private

  attr_accessor :filecommand
  attr_writer   :path, :config

  pre 'pth nonempty string' do |pth| ! pth.nil? && ! pth.empty? end
  def initialize pth
    self.path = pth
    self.config = Configuration.config
    self.filecommand = FileCommand.new
  end

end
