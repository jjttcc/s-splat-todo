require 'date'
require_relative 'actiontarget'

# Actions or specific designations of work that need to be completed
class Task
  include ActionTarget

  attr_reader :due_date

  def initialize spec
    super spec
    if spec.due_date != nil then
#!!!!!!To-do: handle exception:
      @due_date = DateTime.parse(spec.due_date)
p "due date: #{@due_date}"
    end
  end
end
