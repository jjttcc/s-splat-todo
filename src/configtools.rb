# configuration-related tools
module ConfigTools
  include SpecTools

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

  def self.config_dir_path
    result = ""
    if ENV[ST_CONFIG_PATH] then
      result = ENV[ST_CONFIG_PATH]
    else
      result = constructed_path([self::home_path, '.config', 'stodo'])
    end
    result
  end

  # path of the configuration directory
  CONFIG_DIR_PATH = self.config_dir_path
  # path of the configuration file
  CONFIG_FILE_PATH = self.constructed_path([CONFIG_DIR_PATH, 'config'])
  ### config tags
  SPEC_PATH_TAG      = 'specpath'
  DATA_PATH_TAG      = 'datapath'
  OLD_SPECS_TAG      = 'processed_specs'
  EMAIL_TEMPLATE_TAG = 'emailtemplate'

end
