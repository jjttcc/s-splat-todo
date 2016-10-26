require_relative 'stodospec'

# "gatherer" of specifications stored in files
class FileBasedSpecGatherer
  include SpecTools

  # the gathered specs, one object per file
  attr_reader :specs

  public

  # Perform any needed "clean up" operations after "gathering" new specs.
  def initial_cleanup new_handle
    require 'fileutils'
    # Move the spec files out of the "spec_path" and into the
    # "post_init_spec_path" so that they are not seen/used again during
    # subsequent runs.
    @specs.each do |s|
      if new_handle[s.handle] then
        cur_specfile_path = s.input_file_path
        if File.exists? cur_specfile_path then
          FileUtils.mv(cur_specfile_path, @config.post_init_spec_path)
        end
      end
    end
  end

  private

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
        s = spec_for(path)
        if s.valid? then
          @specs << s
        else
          # Leave the invalid spec file as is.
          $log.warn("Invalid spec for '#{s.title}': #{s.reason_for_invalidity}")
        end
      end
    end
  end

  def spec_for path
    STodoSpec.new(path, @config)
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
