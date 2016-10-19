# configuration-related tools
module ConfigTools
  public

  def self.home_path
    result = ENV['HOME']
    if not result then result = ENV['STODO_HOME'] end
    if not result then
      raise "Missing environment variable: HOME or STODO_HOME must be set."
    end
    result
  end

  def self.constructed_path paths
    result = "."
    if paths != nil then result = paths.join(File::SEPARATOR) end
    result
  end

  # path of the configuration directory
  CONFIG_DIR_PATH = constructed_path([self::home_path, '.config', 'stodo'])
  # path of the configuration file
  CONFIG_FILE_PATH = self.constructed_path([CONFIG_DIR_PATH, 'config'])
  ### config tags
  SPEC_PATH_TAG      = 'specpath'
  DATA_PATH_TAG      = 'datapath'
  OLD_SPECS_TAG      = 'processed_specs'
  EMAIL_TEMPLATE_TAG = 'emailtemplate'

end
