require 'ruby_contracts'

module ReportTools
  include Contracts::DSL, Util

  public

  def label; nil end

  COUNT_LIMIT  = 5
  BORDER       = "#{"=" * 76}\n"
  MINOR_BORDER = "#{"-" * 62}\n"

  # Summary of the counts of components of 'report'
  pre  :rep_good do |h| h[:report] != nil && h[:report].is_a?(Enumerable) end
  pre  :lbl_good do |h| h[:label].nil? || h[:label].is_a?(String)         end
  pre  :cl_good  do |h|
    h[:count_limit].nil? || h[:count_limit].is_a?(Integer) end
  post :result do |result| result != nil end
  def count_summary(report:, count_limit: COUNT_LIMIT, label: "")
    result = label
    same_counts = {}
    if ! result.empty? then
      result += ":\n"
    end
    count_lines = {}
    max_handle_length = 0
    report.each do |e|
      if e.handle.length > max_handle_length then
        max_handle_length = e.handle.length
      end
      if ! count_lines.has_key?(e.count) then
        count_lines[e.count] = [e.handle]
      else
        count_lines[e.count] << e.handle
      end
    end
    count_lines.keys.sort.each do |k|
      if count_lines[k].count > count_limit then
        same_counts[k] = count_lines[k].count
      else
        result += sprintf("%-#{max_handle_length + 2}s %s\n",
          count_lines[k].join(", ") + ":", number_with_delimiter(k))
      end
    end
    same_counts.keys.each do |count|
      result += "#{same_counts[count]} elements with count: #{count}\n"
    end
    result
  end

  MSG_SUB_SAMPLE_SIZE = 3

  # Information extracted from a TopicReport
  pre :topic_report do |hash|
    hash[:report] != nil && hash[:report].is_a?(TopicReport) end
  def topic_info(report:, count_limit: COUNT_LIMIT, label: "")
    result = ""   # (Ignore 'label'.)
    indent = 2
    subreport = lambda do |starti, endi|
      (starti..endi).each do |i|
        c = report[i]
        result +=
          "#{" " * indent}#{c.handle} - timestamp: #{c.datetime}, messages:\n"
        indent += 2
        c.labels.each do |l|
          result +=  "#{" " * indent}#{l}: #{c.message_for(l)}\n"
        end
        indent -= 2
      end
    end
    if report.count > count_limit then
      result += "first 3 components:\n"
      subreport.call(0, MSG_SUB_SAMPLE_SIZE - 1)
      result += "last 3 components:\n"
      subreport.call(report.count - MSG_SUB_SAMPLE_SIZE, report.count - 1)
    else
      result += "all #{report.count} components:\n"
      subreport.call(0, report.count - 1)
    end
    result
  end

  # Information extracted from a TopicReport
  pre :status_report do |hash|
    hash[:report] != nil && hash[:report].is_a?(StatusReport) end
  def status_info(report:, count_limit: COUNT_LIMIT, label: "")
    result = ""   # (Ignore 'label'.)
    indent = 2
    result += "#{report.count} sub-reports:\n"
    report.each do |tr|
      result +=  "#{tr.summary(nil, indent, method(:number_with_delimiter))}" \
        "\n#{MINOR_BORDER}"
    end
    result
  end

  COL_SEP_MARGIN = 3
  def formatted_two_column_list(l, col1func, col2func, sep_str = ':')
    result = ""
    max_col_length = 0
    col1s, col2s = [], []
    l.each do |o|
      s = col1func.call(o)
      if s.length > max_col_length then
        max_col_length = s.length
      end
      col1s << s
      col2s << col2func.call(o)
    end
    sep_spaces = max_col_length + COL_SEP_MARGIN
    (0..col1s.count - 1).each do |i|
      result += sprintf("%-#{sep_spaces}s %s\n",
                        col1s[i] + sep_str, col2s[i])
    end
    result
  end

  pre :target_enum_or_has_matches_for do |tgt|
    tgt != nil && (tgt.is_a?(Enumerable) || tgt.respond_to?(:matches_for)) end
  def collected_matches(target, regexp, use_keys, use_values, negate)
    result = []
    if target.respond_to?(:matches_for) then
      result = target.matches_for(regexp, use_keys: use_keys,
                                  use_values: use_values, negate: negate)
    else
      target.each do |o|
        matches = o.matches_for(regexp, use_keys: use_keys,
                                use_values: use_values, negate: negate)
        if matches != nil && matches.count > 0 then
          if matches.is_a?(Array) then
            result.concat(matches)
          else
            result << matches
          end
        end
      end
    end
    result
  end

  # Return a line-wrapped version of the specified string, 's'.
  # (Borrowed/adapted from NateSHolland [
  # https://stackoverflow.com/users/1415546/natesholland ] at
  # https://stackoverflow.com/questions/49244740/wrap-the-long-lines-in-ruby )
  pre  :s_exists do |s| s != nil && s.is_a?(String) end
  pre  :sane_indent do |s, mxlen, ind| ind.nil? || ind.length < mxlen end
  post :exists do |result, s| result != nil && result.length >= s.length end
  def wrap(s, max_length = 72, indent = nil)
    result = ""
    line1_length, line_n_length = max_length, max_length
    if indent != nil && indent.length > 0 then
      line_n_length = max_length - indent.length
    end
    word_array = s.split(/\s|-/)
    line = word_array.shift
    max_len = line1_length
    adjust_lengths = lambda do
      if ! line1_length.nil? then
        max_len = line_n_length
        line1_length = nil
      end
    end
    word_array.each do |word|
      if (line + " " + word).length <= max_len then
        line << " " + word
      elsif word.length > max_len then
        result << line + "\n#{indent}" unless line.empty?
        adjust_lengths.call
        line = ""
        word.each_char do |c|
          line << c
          if line.length == max_len then
            result << line + "\n#{indent}"
            adjust_lengths.call
            line = ""
          end
        end
      else
        result << line + "\n#{indent}"
        adjust_lengths.call
        line = word
      end
    end
    result << line
    result
  end

  # DateTime obtained from user - if 'refresh', take the "refresh" the
  # internal state (such as timezone offset).
  def prompted_datetime(dt_label, refresh = true)
    result = nil
    finished = false
    if dt_label.nil? then
      dt_label = ""
    elsif ! dt_label.empty? then
      dt_label = "<#{dt_label}> "
    end
    if @now.nil? || refresh then
      @now = DateTime.now
    end
    timezone_offset = (@now.utc_offset / 3600).to_s
    dt_template = [@now.year, @now.month, @now.day, @now.hour, @now.minute, 0]
    prompt = TTY::Prompt.new
    while ! finished do
      response = prompt.ask("Enter #{dt_label}date/time (empty for \"now\")")
      if response.nil? then
        result = @now
      else
        dt_parts = []
        i = 0
        response_parts = response.split(/[-\/ :]+/)
        (0..5).each do |i|
          part = response_parts[i]
          if ! is_i?(part) then
            case part
            when /[._a-wyz]/
              dt_parts[i] = dt_template[i]
            when /x/
              n = 0
              if i == 1 || i == 2 then                # month or day
                n = 1
              end
              dt_parts[i] = n
            when nil
              dt_parts[i] = dt_template[i]
            end
          else
            dt_part = part.to_i
            if dt_part == 0 && (i == 1 || i == 2) then    # month or day
              dt_part = 1    # Correct to valid month-or-day.
            end
            dt_parts[i] = dt_part
          end
        end
        y, m, d, h, min, s = dt_parts
        result = DateTime.new(y, m, d, h, min, s, timezone_offset)
      end
      puts "#{dt_label}date/time: #{result}"
      response = prompt.ask('OK?')
      if response =~ /y/i then
        finished = true
      end
    end
    result
  end

end
