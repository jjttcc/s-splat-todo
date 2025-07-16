require 'work_command'
require 'base_report'
require 'handle_report'
require 'complete_report'
require 'children_report'
require 'string_extensions'
require 'fileutils'

class ReportCommand < WorkCommand
  include CommandConstants, Contracts::DSL

  attr_reader :report_dispatch

  def initialize(config)
    super(config)
    @report_dispatch = {
      "handle"   => HandleReport,
      "complete" => CompleteReport,
      "children" => ChildrenReport
    }
  end

  def do_execute(the_caller)
    report_type = arg1
    criteria_arg = arg2
    if ! remaining_args.nil? && ! remaining_args.empty? then
      criteria_arg = "#{criteria_arg} #{remaining_args.join(' ')}"
    end
    failure_message = ""
    execution_succeeded_local = false
    report_content = nil
    if report_type.nil? || report_type.empty? then
      # Default behavior: list all target handles
      handles = database.handles
      if handles.empty? then
        failure_message = "No items found."
      else
        report_content = handles.join("\n")
        execution_succeeded_local = true
      end
    else
      processed_criteria = criteria(criteria_arg)
      if report_type == "children" && (criteria_arg.nil? || criteria_arg.empty?) then
        # For 'report children' without a specific handle, get all top-level items
        processed_criteria = database.handles.select do |h|
          target = database[h]
          target && target.parent_handle.nil?
        end.sort
        if processed_criteria.empty? then
          failure_message = "No top-level items found."
        end
      end

      if processed_criteria.nil? then
        # Error in processing criteria, message already set by process_criteria
        failure_message = self.response # Copy message from process_criteria
      else
        # Ensure processed_criteria is always an array
        if ! processed_criteria.is_a?(Array) then
          processed_criteria = [processed_criteria]
        end
        report_class = report_dispatch[report_type]
        if report_class.nil? then
          failure_message = "Report type '#{report_type}' not yet implemented."
        else
          report_generator = report_class.new(database, recursive, short_format)
          report_content =
            report_generator.report(processed_criteria)
          if report_content.nil? then
            failure_message = report_generator.message
          else
            execution_succeeded_local = true
          end
        end
      end
    end
    self.response = failure_message
    self.execution_succeeded = execution_succeeded_local
    # If report_content is not nil, it will be published by ClientRequestHandler
    # via self.response
    if execution_succeeded_local && ! report_content.nil? then
      self.response = report_content
    end
  end

  private

  def criteria(criteria_arg)
    result = nil
    message_local = ""
    if criteria_arg.nil? || criteria_arg.empty? then
      # No criteria specified, result remains nil
    elsif criteria_arg.start_with?("handle:") then
      regex_str = criteria_arg.sub("handle:", '')
      result = filter_handles_by_regex(regex_str) do |target, regex|
        target.handle =~ regex
      end
      if result.nil? then
        message_local = self.response # Copy from filter_handles_by_regex
      end
    elsif criteria_arg.start_with?("title:") then
      regex_str = criteria_arg.sub("title:", '')
      result = filter_handles_by_regex(regex_str) do |target, regex|
        (target.title || "") =~ regex
      end
      if result.nil? then
        message_local = self.response # Copy message from filter_handles_by_regex
      end
    elsif criteria_arg.start_with?("descr:") then
      regex_str = criteria_arg.sub("descr:", '')
      result = filter_handles_by_regex(regex_str) do |target, regex|
        (target.description || "") =~ regex
      end
      if result.nil? then
        message_local = self.response # Copy message from filter_handles_by_regex
      end
    elsif criteria_arg.start_with?("pri:") then
      values_str = criteria_arg.split(':', 2)[1]
      result = filter_handles_by_list(values_str) do |target, value|
        (target.priority || "").to_s == value
      end
      if result.nil? then
        message_local = self.response # Copy message from filter_handles_by_list
      end
    elsif criteria_arg.start_with?("stat:") then
      values_str = criteria_arg.split(':', 2)[1]
      result = filter_handles_by_list(values_str) do |target, value|
        (target.state.value || "").to_s == value
      end
      if result.nil? then
        message_local = self.response # Copy message from filter_handles_by_list
      end
    elsif criteria_arg.start_with?("type:") then
      values_str = criteria_arg.split(':', 2)[1]
      result = filter_handles_by_list(values_str) do |target, value|
        (target.type || "").to_s == value
      end
      if result.nil? then
        message_local = self.response # Copy message from filter_handles_by_list
      end
    else
      result = criteria_arg.tokenize # Use tokenize for multiple handles
    end
    if ! message_local.empty? then
      self.response = message_local
      result = nil
    end
    result
  end

  def filter_handles_by_list(values_str, &block)
    result = nil
    message_local = ""
    values = values_str.split(',').map(&:strip)
    if values.empty? then
      message_local = "No values provided for filter."
    else
      matching_handles = database.handles.select do |h|
        target = database[h]
        target && values.any? { |value| block.call(target, value) }
      end
      if matching_handles.empty? then
        message_local = "No items matching any of the provided values found."
      else
        result = matching_handles
      end
    end
    if ! message_local.empty? then
      self.response = message_local
      result = nil
    end
    result
  end

  def filter_handles_by_regex(regex_str, &block)
    result = nil
    message_local = ""
    begin
      regex = Regexp.new(regex_str)
      matching_handles = database.handles.select do |h|
        target = database[h]
        target && block.call(target, regex)
      end
      if matching_handles.empty? then
        message_local = "No items matching /#{regex_str}/ found."
      else
        result = matching_handles
      end
    rescue RegexpError => e
      message_local = "Invalid regex '#{regex_str}': #{e.message}"
    end
    if ! message_local.empty? then
      self.response = message_local
      result = nil
    end
    result
  end

end

