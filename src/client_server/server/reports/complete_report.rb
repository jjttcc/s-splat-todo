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
  def stodo_item_report(target, indent = "")
    report_lines = []
    # Define labels and their corresponding values/methods
    report_data = {
      "Handle:"     => target.handle,
      "Type:"       => target.type,
      "Title:"      => target.title,
      "Description:"=> target.description,
      "Parent:"     => target.parent_handle || 'None',
      "Children:"   => (target.children || []).map(&:handle).join(', '),
      "Status:"     => target.state.value,
      "Priority:"   => target.priority
    }
    max_label_len = report_data.keys.map(&:length).max
    report_data.each do |label, value|
      report_lines << "#{indent}#{label.ljust(max_label_len)} #{value}".rstrip
    end
    result = report_lines.join("\n") + "\n"   # End with a newline.
    if recursive then
      target.children.each do |child|
        result += stodo_item_report(child, indent + "  ")
      end
    end
    result
  end
end

