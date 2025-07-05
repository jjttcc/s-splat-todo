require_relative 'base_report'

class HandleReport < BaseReport

  def report(criteria)
    result = []
    fail_msg_local = ""
    if criteria.nil? || criteria.empty? then
      fail_msg_local = "'handle' report type requires a handle as criteria."
    else
      criteria.each do |handle|
        target = @database[handle]
        if target.nil? then
          result << "Warning: Item with handle '#{handle}' not found."
        else
          result << target.handle
        end
      end
      if result.empty? then
        fail_msg_local = "No items found for report."
      end
    end
    if ! fail_msg_local.empty? then
      set_fail_msg(fail_msg_local)
      result = nil
    else
      result = result.join("\n")
    end
    result
  end

end
