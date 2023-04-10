require 'ruby_contracts'
require 'filetypetools'
require 'externalcommand'

# Abstraction for handlers of files of different media types, for "handling" -
# viewing (video), playing (audio), viewing (document), editing (document),
# processing (e.g., executing a program or script), etc. - the files
class MediaHandler
  include Contracts::DSL
  include FileTypeTools

  public

  ###  Access

  attr_reader :path, :config

  ###  Basic operations

  # Invoke the appropriate command, cmd, to edit the file at self.path.
  # If self.path is a directory, call 'Dir.chdir self.path' before invoking
  # cmd on self.path.
  def edit
    type = filecommand.mime_type self.path
    stodo_type = file_type_for type
    if ! BASIC_FILE_TYPES.include?(stodo_type) then
      $log.error "file type - #{type} - is not configured"
    else
      if is_directory stodo_type then
        Dir.chdir self.path
      end
      external_editor_spec = config.media_editor_for stodo_type
      cmd_with_args = string_as_argument_array external_editor_spec
      begin
        ExternalCommand.execute(*cmd_with_args, self.path)
      rescue Exception => e
        $log.error "error editing #{self.path}: #{e}"
      end
    end
  end

  # Invoke the appropriate command, cmd, to view the file at self.path.
  # If self.path is a directory, call 'Dir.chdir self.path' before invoking
  # cmd on self.path.
  def view
    type = FileCommand::mime_type self.path
    stodo_type = file_type_for type
    if ! BASIC_FILE_TYPES.include?(stodo_type) then
      $log.error "file type - #{type} - is not configured"
    else
      if is_directory stodo_type then
        Dir.chdir self.path
      end
      external_viewer_spec = config.media_viewer_for stodo_type
      cmd_with_args = string_as_argument_array external_viewer_spec
      begin
        ExternalCommand.execute(*cmd_with_args, self.path)
      rescue Exception => e
        $log.error "error viewing #{self.path}: #{e}"
      end
    end
  end

  # Assume 'path' is a directory: If a "stodo shell file" exists in 'path',
  # execute it.
  pre 'attlist valid' do |attlist| ! attlist.nil? && attlist.is_a?(Array) end
  def execute_shell attachment_list
    shellfile = config.stodo_shell path
    apaths = attachment_list.map do |a| a.path end
    if ! shellfile.nil? then
        if ExternalCommand.valid_executable shellfile then
          ExternalCommand.execute(shellfile, *apaths)
        else
          $log.warn "stodo shell file is not executable or not readable: "\
            "#{shellfile}"
        end
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
