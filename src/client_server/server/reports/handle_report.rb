require_relative 'base_report'

class HandleReport < BaseReport

  def report(criteria, recursive = false)
    result = []
    message_local = ""
    if criteria.nil? || criteria.empty? then
      message_local = "'handle' report type requires a handle as criteria."
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
        message_local = "No items found for report."
      end
    end
    if ! message_local.empty? then
      set_message(message_local)
      result = nil
    else
      result = result.join("\n")
    end
    result
  end

end
