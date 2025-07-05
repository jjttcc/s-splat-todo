require_relative 'base_report'

class CompleteReport < BaseReport
  def report(criteria)
    result = []
    fail_msg_local = ""

    if criteria.nil? || criteria.empty? then
      fail_msg_local = "'complete' report type requires a handle as criteria."
    else
      criteria.each do |handle|
        target = @database[handle]
        if target.nil? then
          result << "Warning: Item with handle '#{handle}' not found."
        else
          result << generate_single_report(target)
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
      result = result.join("\n---\n") # Separate reports with a line
    end
    result
  end

  private

  def generate_single_report(target)
    report_str = "Handle: #{target.handle}\n"
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

    report_str += "  #{labels[0].ljust(max_label_len)} #{target.type}\n"
    report_str += "  #{labels[1].ljust(max_label_len)} #{target.title}\n"
    report_str += "  #{labels[2].ljust(max_label_len)} #{target.description}\n"
    report_str += "  #{labels[3].ljust(max_label_len)} " +
                  "#{target.parent_handle || 'None'}\n"
    report_str += "  #{labels[4].ljust(max_label_len)} " +
                  "#{(target.children || []).map(&:handle).join(', ')}\n"
    report_str += "  #{labels[5].ljust(max_label_len)} #{target.state.value}\n"
    report_str += "  #{labels[6].ljust(max_label_len)} #{target.priority}\n"
    return report_str
  end
end

