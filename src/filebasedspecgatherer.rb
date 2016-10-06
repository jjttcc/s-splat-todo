require_relative 'stodospec'

# "gatherer" of specifications stored in files
class FileBasedSpecGatherer
  # the gathered specs, one object per file
  attr_reader :specs

  private

  def initialize config
    @specs = []
    oldpath = Dir.pwd
    Dir.chdir config.spec_path
    process_specs
    Dir.chdir oldpath
@specs.each do |s|
  puts '-' * 68
  puts "type: #{s.type}"
  puts "title: #{s.title}"
  puts "description: #{s.description}"
  puts "start: #{s.start_date}"
  puts "due_date: #{s.due_date}"
  puts "goal: #{s.goal}"
  puts "handle: #{s.handle}"
  puts "reminders: #{s.reminders}"
  puts "comment: #{s.comment}"
end
  end

  def process_specs
    d = Dir.new '.'
    d.each do |filename|
      if filename !~ /^\./
        @specs << spec_for(filename)
      end
    end
  end

  def spec_for fn
    contents = File.read fn
    STodoSpec.new contents
#  attr_accessor :type, :title, :description, :handle, :priority, :start,
#    :due_date, :goal, :reminder_dates, :comment, :parent
  end
end
