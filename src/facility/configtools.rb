require 'ruby_contracts'

# configuration-related tools
module ConfigTools
  include SpecTools
  include Contracts::DSL

  public

  ###  Access

  # Path to the git executable (e.g.: /bin/git)
  def git_executable
    '/bin/git'    # (default - Redefine this method to override.)
  end

  # Path to the git executable (e.g.: /bin/git)
  post 'exists' do |result| ! result.nil? end
  def git_path
    raise "abstract method: #{__method__}"  # Redefine to use.
  end

  # The "global" git-repository object
  post 'exists' do |result| ! result.nil? && result.is_a?(STodoGit) end
  def stodo_git
    raise "abstract method: #{__method__}"  # Redefine to use.
  end

  # Arguments (Array) to 'git' command to produce a list of files in repo:
  def git_lsfile_args
    [
      # Forces 'git' to use #{git_path} as its repo/root-directory:
      "--git-dir=#{git_path}/.git",
      'ls-tree', '--full-tree', '-r', '--name-only', 'HEAD'
    ]
  end

  # Arguments (Array) to 'git log' command to produce log output for the
  # specified files (handles), which are expected to exist within the
  # repository:
  pre 'handles is array' do |hndls| ! hndls.nil? && hndls.is_a?(Array) end
  def git_log_args(handles)
    result = [
      # Forces 'git' to use #{git_path} as its repo/root-directory:
      "--git-dir=#{git_path}/.git", 'log', '--',
    ]
    result.concat(handles)
    result
  end

  # Arguments (Array) to the 'git show' command to output the specified
  # version (id) of the specified file (handle).
  pre 'id-exists' do |id| ! id.nil? && ! id.empty? end
  pre 'handle-exists' do |handle| ! handle.nil? && ! handle.empty? end
  def git_show_args(id, handle)
    result = [
      # Forces 'git' to use #{git_path} as its repo/root-directory:
      "--git-dir=#{git_path}/.git", 'show', "#{id}:#{handle}"
    ]
    result
  end

  # Arguments (Array) to 'git mv' command to "move" 'old_handle' to
  # 'new_handle':
  pre 'handles is array' do |hndls| ! hndls.nil? && hndls.is_a?(Array) end
  def git_mv_args(old_handle, new_handle)
    result = [
      # Forces 'git' to use #{git_path} as its repo/root-directory:
      "--git-dir=#{git_path}/.git", 'mv', '--', old_handle, new_handle
    ]
    result
  end

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

  # Path of the configuration directory
  CONFIG_DIR_PATH = self.config_dir_path
  # Path of the configuration file
  CONFIG_FILE_PATH = self.constructed_path([CONFIG_DIR_PATH, 'config'])
  # Name of executable "stodo shell" file:
  STODO_SHELL_FILE_NAME = '.stodo-shell'
  # git-related settings:
  DEFAUT_GIT_DIR   = 'git'
  # The standard ".git" repository directory:
  GIT_REPO_DIR     = '.git'
  ### config tags
  SPEC_PATH_TAG        = 'specpath'
  DATA_PATH_TAG        = 'datapath'
  USER_PATH_TAG        = 'userpath'
  GIT_PATH_TAG         = 'gitpath'
  GIT_EXE_PATH_TAG     = 'gitexe'
  DEFAUT_GIT_EXE_TAG   = '/usr/bin/git'
  BACKUP_PATH_TAG      = 'backuppath'
  OLD_SPECS_TAG        = 'processed_specs'
  EMAIL_TEMPLATE_TAG   = 'emailtemplate'
  DEFAULT_EMAIL_TAG    = 'default_email'
  CALENDAR_COMMAND_TAG = 'calendarcmd'
  USER_TAG             = 'user'
  CATEGORY_PREFIX_TAG  = 'categoryprefix'
  DEFAULT_CAT_PREFIX   = 'cat:'
  ATTCH_ACTION_EDIT    = 'edit'
  ATTCH_ACTION_VIEW    = 'view'

  # The full path of the "stodo" executable "shell" file (i.e.,
  # STODO_SHELL_FILE_NAME) in the specified 'path'
  # nil if no such "physical" file actually exists at the time of execution
  # or if the object exists but is not a regular file
  pre 'path is absolute' do |path|
    ! path.nil? && path.is_a?(String) && path[0] == "/"
  end
  pre 'path exists and is a directory' do |path| Dir.exist?(path) end
  def stodo_shell(path)
    result = File.join(path, STODO_SHELL_FILE_NAME)
    if ! File.file?(result) then
      result = nil
    end
    result
  end

  # http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby)
  # The path of the executable `cmd', if it is in the user's path -
  # otherwise, nil; if `cmd' is an absolete path of an executable file,
  # `cmd' is returned (unaltered).
  def self.which(cmd)
    result = nil
    if cmd =~ /^\// && File.file?(cmd) && File.executable?(cmd) then
      result = cmd
    else
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        candidate = File.join(path, "#{cmd}")
        if File.file?(candidate) && File.executable?(candidate) then
          result = candidate
          break
        end
        if result != nil then break end
      end
    end
    result
  end

end
