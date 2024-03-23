require 'ruby_contracts'

# Tools to aid with media-related configuration
module MediaConfigTools
  include Contracts::DSL

  public

  ###  Access

  # paths of media viewing/editing executables
  attr_reader :media_tool_paths

  # The path of the external editor for 'stodo_type'
  pre 'type arg valid' do
    |stype| ! stype.nil? && BASIC_FILE_TYPES.include?(stype)
  end
  def media_editor_for stodo_type
    path = self.media_tool_paths[edit_tag(stodo_type)]
    path
  end

  # The path of the external viewer for 'stodo_type'
  pre  'type arg valid' do
    |stype| ! stype.nil? && BASIC_FILE_TYPES.include?(stype)
  end
  post 'result not empty' do |result| ! result.nil? && ! result.empty? end
  def media_viewer_for stodo_type
    path = self.media_tool_paths[view_tag(stodo_type)]
    path
  end

  ###  Constants

  VIEW_PREFIX = 'view_'
  EDIT_PREFIX = 'edit_'

  BASIC_FILE_TYPES = [
    # Definition of constants -> symbols representing "basic" file types
    MSWORD      =  :msword,
    MSEXCEL     =  :msexcel,
    ODFSPREAD   =  :odfspread,
    ODFTEXT     =  :odftext,
    OPENXML     =  :openxml,
    EXECUTABLE  =  :executable,
    PLAIN_TEXT  =  :plain_text,
    TEXT_DATA   =  :text_data,
    PDF         =  :pdf,
    VIDEO       =  :video,
    CODE        =  :code,
    AUDIO       =  :audio,
    DIRECTORY   =  :directory,
  ]

  BASIC_FILE_TYPE_TAGS = {}
  # Configuration tags for media viewers/editors
  #   Define constants:
  #     MSWORD_VIEWER_TAG, MSWORD_EDITOR_TAG, etc.:
  BASIC_FILE_TYPES.each do |t|
    tname = t.to_s
    const_view_name = tname.upcase + '_VIEWER_TAG'
    const_edit_name = tname.upcase + '_EDITOR_TAG'
    view_tag = VIEW_PREFIX + tname
    edit_tag = EDIT_PREFIX + tname
    const_set(const_view_name, view_tag)
    const_set(const_edit_name, edit_tag)
    BASIC_FILE_TYPE_TAGS[const_view_name] = view_tag
    BASIC_FILE_TYPE_TAGS[const_edit_name] = edit_tag
  end

  private

  # Set @media_tool_paths, using the config values in 'settings'.
  pre '"settings" valid' do |settings|
    ! settings.nil? && settings.is_a?(Hash)
  end
  def set_external_media_tools settings
    @media_tool_paths = {}
    BASIC_FILE_TYPE_TAGS.values.each do |v|
      @media_tool_paths[v] = settings[v]
    end
  end

  # 'edit_' + stodo_type.to_s
  def edit_tag stodo_type
    result = ""
    if ! stodo_type.nil? then
      result = EDIT_PREFIX + stodo_type.to_s
    end
    result
  end

  # 'view_' + stodo_type.to_s
  def view_tag stodo_type
    result = ""
    if ! stodo_type.nil? then
      result = VIEW_PREFIX + stodo_type.to_s
    end
    result
  end

end
