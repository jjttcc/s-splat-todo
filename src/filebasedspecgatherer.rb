require_relative 'stodospec'

# "gatherer" of specifications stored in files
class FileBasedSpecGatherer
  include SpecTools

  # the gathered specs, one object per file
  attr_reader :specs, :spec_files

  public

  # Perform any needed "clean up" operations after "gathering" new specs.
  def initial_cleanup
    require 'fileutils'
    sep = File::SEPARATOR
    # Move the spec files out of the "spec_path" and into the "data_path"
    # so that they are not seen/used again during initial processing.
    @spec_files.each do |f|
      FileUtils.mv(@config.spec_path + sep + f, @config.data_path)
    end
  end

  private

  def initialize config
    @specs = []
    @spec_files = []
    @config = config
    oldpath = Dir.pwd
    Dir.chdir config.spec_path
    process_specs
    Dir.chdir oldpath
    if ENV[STDEBUG] then
      display_specs
    end
  end

  ### Internal implementation

  def process_specs
    d = Dir.new '.'
    d.each do |filename|
      if File.file?(filename) && filename !~ /^\./ then
        @specs << spec_for(filename)
        @spec_files << filename
      end
    end
  end

  def spec_for fn
    STodoSpec.new fn, @config
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
