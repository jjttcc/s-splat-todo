require 'ruby_contracts'
require 'filetypetools'
require 'externalcommand'

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
    external_editor_spec = config.media_editor_for stodo_type
    cmd_with_args = string_as_argument_array external_editor_spec
    begin
      ExternalCommand.execute(*cmd_with_args, self.path)
    rescue Exception => e
      $log.warn "error editing #{self.path}: #{e}"
    end
  end

  # Invoke the appropriate command to view the file at self.path.
  def view
    type = filecommand.mime_type self.path
    stodo_type = file_type_for type
    external_viewer_spec = config.media_viewer_for stodo_type
    cmd_with_args = string_as_argument_array external_viewer_spec
    begin
      ExternalCommand.execute(*cmd_with_args, self.path)
    rescue Exception => e
      $log.warn "error viewing #{self.path}: #{e}"
    end
  end

  private

  attr_accessor :filecommand
  attr_writer   :path, :config

  pre 'pth nonempty string' do |pth| ! pth.nil? && ! pth.empty? end
  def initialize pth
    self.path = pth
    self.config = Configuration.instance
    self.filecommand = FileCommand.new
  end

  def string_as_argument_array s
    result =
      s.scan(/(?:["']([^"]*)["']|([^ ]+))/).flatten.select {|e| !e.nil? }
    result
  end

end
