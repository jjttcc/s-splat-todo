require_relative 'base_report'

class CompleteReport < BaseReport

  def report(criteria)
    result = []
    message_local = ""
    if criteria.nil? || criteria.empty? then
      message_local = "'complete' report type requires a handle as criteria."
    else
      criteria.each do |handle|
        target = @database[handle]
        if target.nil? then
          result << "Warning: Item with handle '#{handle}' not found."
        else
          result << stodo_item_report(target)
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
      result = result.join("\n---\n") # Separate reports with a line
    end
    result
  end

  private

  # A report for the specified STodoTarget item - 'target'
  def stodo_item_report(target)
#!!!to-do: Need an indent
#!!!![reminder: Get rid of 'got ' in the response]
    result = "Handle: #{target.handle}\n"
    labels = [
      "Type:",
      "Title:",
      "Description:",
      "Parent:",
      "Children:",
      "Status:",
      "Priority:"
    ]
    max_label_len = labels.map(&:length).max
    result += "  #{labels[0].ljust(max_label_len)} #{target.type}\n"
    result += "  #{labels[1].ljust(max_label_len)} #{target.title}\n"
    result += "  #{labels[2].ljust(max_label_len)} #{target.description}\n"
    result += "  #{labels[3].ljust(max_label_len)} " +
                  "#{target.parent_handle || 'None'}\n"
    result += "  #{labels[4].ljust(max_label_len)} " +
                  "#{(target.children || []).map(&:handle).join(', ')}\n"
    result += "  #{labels[5].ljust(max_label_len)} #{target.state.value}\n"
    result += "  #{labels[6].ljust(max_label_len)} #{target.priority}\n"
    if recursive then
      target.children.each do |child|
        result = result + stodo_item_report(child)
      end
    end
    result
  end
end

