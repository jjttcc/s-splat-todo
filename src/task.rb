require 'date'
require_relative 'actiontarget'

# Actions or specific designations of work that need to be completed
class Task
  include ActionTarget

  attr_reader :due_date

  def initialize spec
    super spec
    if spec.due_date != nil then
      begin
        @due_date = DateTime.parse(spec.due_date)
      rescue ArgumentError => e
        # spec.due_date is invalid, so leave @due_date as nil.
        $log.error "due_date invalid [#{e}] (#{spec.due_date}) in #{self}"
      end
    end
  end
end
