require 'ruby_contracts'
require 'stodospec'

# "gatherer" of specifications stored in files
class FileBasedSpecGatherer
  include SpecTools, Contracts::DSL

  public

  #####  Access

  # the gathered specs, one object per file
  attr_reader :specs
  # the current app configuration
  attr_reader :config

  public

  #####  Basic operations

  # Perform any needed "clean up" operations after "gathering" new specs.
  def initial_cleanup new_handle
    require 'fileutils'
    # Move the spec files out of the "spec_path" and into the
    # "post_init_spec_path" so that they are not seen/used again during
    # subsequent runs.
    @specs.each do |s|
      if new_handle[s.handle] then
        cur_specfile_path = s.input_file_path
        if File.exist? cur_specfile_path then
          archive_spec_file(cur_specfile_path)
        end
      end
    end
  end

  private

  pre 'config exists' do |config| ! config.nil? end
  def initialize config, new_specs = true
    @specs = []
    @config = config
    path = new_specs ? @config.spec_path : @config.post_init_spec_path
    process_specs path
    if ENV[STDEBUG] then
      display_specs
    end
  end

  ### Internal implementation

  def process_specs spec_path
    d = Dir.new spec_path
    d.each do |filename|
      path = spec_path + File::SEPARATOR + filename
      if
        File.file?(path) && filename !~ /^\./ then
        s = new_spec_for(path)
        if s.valid? then
          @specs << s
        else
          # Leave the invalid spec file as is.
          $log.warn("Invalid spec for '#{s.title}': #{s.reason_for_invalidity}")
        end
      end
    end
  end

  def new_spec_for path
    STodoSpec.new(path, @config)
  end

  def archive_spec_file source_path
    base_target_path = @config.post_init_spec_path + File::SEPARATOR +
      File.basename(source_path)
    if File.exist?(base_target_path) then
      target_path = "#{base_target_path}" + (rand).to_s[1..-1]
      while File.exist?(target_path) do
        target_path = "#{base_target_path}" + (rand).to_s[1..-1]
      end
    else
      target_path = base_target_path
    end
    # Note: There is a very small chance that some other process will create
    # a file with this path after the above logic and before this call:
    FileUtils.mv(source_path, target_path)
  end

  ### Debugging/testing

  def display_specs
    @specs.each do |s|
      puts '-' * 68
      puts "type: #{s.type}"
      puts "title: #{s.title}"
      puts "categories: #{s.categories}"
      puts "description: #{s.description}"
      puts "start: #{s.start_date}"
      puts "due_date: #{s.due_date}"
      puts "goal: #{s.goal}"
      puts "handle: #{s.handle}"
      puts "reminders: #{s.reminders}"
      puts "comment: #{s.comment}"
      puts "expire date: #{s.expiration_date}"
    end
  end

end
