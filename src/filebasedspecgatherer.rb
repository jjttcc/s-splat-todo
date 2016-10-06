require_relative 'stodospec'

# "gatherer" of specifications stored in files
class FileBasedSpecGatherer
  # the gathered specs, one object per file
  attr_reader :specs

  private

  def initialize config
#p "spec methods early list: #{STodoSpec.instance_methods}"
    @specs = []
    oldpath = Dir.pwd
    Dir.chdir config.spec_path
    process_specs
    Dir.chdir oldpath
@specs.each do |s|
  p '=' * 68
  p "type: #{s.type}"
  p "title: #{s.title}"
  p "description: #{s.description}"
  p "start: #{s.start_date}"
  p "due_date: #{s.due_date}"
  p "goal: #{s.goal}"
  p "handle: #{s.handle}"
  p "reminders: #{s.reminders}"
  p "comment: #{s.comment}"
end
#p "spec methods late list: #{STodoSpec.instance_methods}"
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
