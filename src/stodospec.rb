require_relative 'spectools'

# Specification for a target (action, project, or memorandum) of the s*todo
# system
class STodoSpec
  include SpecTools

  REMINDER_EXPR, START_EXPR = 'reminders?', 'start[a-z_]*'

  public

  attr_reader :input_file_path

  private

  def initialize input_filename, config
    spec_string = File.read input_filename
    @input_file_path = input_filename
    @config = config
    scan_spec spec_string
  end

  # Scan 'spec_string' for settings and use them to set "self"'s fields.
  def scan_spec spec_string
    cleaned_spec_string = stripped_of_comments(spec_string)
    extract_settings(cleaned_spec_string)
  end

  def method_missing method_name
    result = @setting_for[method_name.to_s]
    result
  end

  ### Scanning helper methods

  def standardized_key k
    result = k
    case result
    when 'start'
      result = 'start_date'
    when 'due'
      result = 'due_date'
    end
    result
  end

  # Adjust any values that need to be "standardized".
  def standardize_values
    type = @setting_for[TYPE_KEY]
    if type then
      @setting_for[TYPE_KEY] = type.downcase
    end
  end

  # Extract the settings implied in `spec_string' and use them to set
  # "self"'s fields.
  def extract_settings spec_string
    split_expr = '('
    for k in [TYPE_KEY, TITLE_KEY, DESCRIPTION_KEY, HANDLE_KEY, PRIORITY_KEY,
        DUE_DATE_KEY, GOAL_KEY, EMAIL_KEY, CALENDAR_KEY, COMMENT_KEY, PARENT_KEY,
        EXPIRATION_DATE_KEY, DATE_TIME_KEY, DURATION_KEY, LOCATION_KEY] do
      split_expr += '^' + k + ':\s*|'
    end
    split_expr += '^' + REMINDER_EXPR + ':\s*|^' + START_EXPR + ':\s*)'
    split_regex = Regexp.new(split_expr)
    components = spec_string.split(split_regex, -1)
    if components.length > 0 and components[0] == "" then
      components.shift  # Remove useless empty first element.
    end
    @setting_for = {}
    if not components.empty? and components.length % 2 == 0 then
      (0 .. components.length - 1).step(2) do |i|
        key = standardized_key(components[i].sub(/: */, ""))
        value = components[i + 1]
        @setting_for[key] = value.chomp
      end
    end
    standardize_values
  end

  # `s' stripped of lines starthing with '#'
  def stripped_of_comments s
    s.gsub(/^#.*/, "")
  end
end
