require 'date'
require_relative 'actiontarget'

# Actions or specific designations of work that need to be completed
class Task
  include ActionTarget

  attr_reader :due_date, :parent_handle

  public

  def has_parent
    self.parent_handle != nil
  end

  private

  def set_fields spec
    super spec
    if spec.due_date != nil then
      begin
        @due_date = DateTime.parse(spec.due_date)
      rescue ArgumentError => e
        # spec.due_date is invalid, so leave @due_date as nil.
        $log.warn "due_date invalid [#{e}] (#{spec.due_date}) in #{self}"
      end
    end
    if spec.parent_handle != nil then
      @parent_handle = spec.parent_handle
    end
  end

end
