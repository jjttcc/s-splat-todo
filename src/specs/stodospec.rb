require 'ruby_contracts'
require 'spectools'

# Specification for a target (action, project, or memorandum) of the s*todo
# system
class STodoSpec
  include SpecTools, Contracts::DSL

  REMINDER_EXPR, START_EXPR = 'reminders?', 'start[a-z_]*'

  public

  attr_reader   :input_file_path, :reference_list
  # All current, stored STodoTarget objects
  attr_accessor :existing_targets, :database

  public

  # Is 'self' a valid/complete specification?
  def valid?
    handle != nil
  end

  # If self is not valid, the reason for it
  def reason_for_invalidity
    result = ""
    if not valid? then
      result = "handle is not set."
    end
    result
  end

  # Is self being used as a template rather than as a normal spec?
  def is_template?
    false
  end

  def to_s
    result = ""
    @setting_for.each do |k, v|
      result += "#{k}: #{v}\n"
    end
    result
  end

  # Check 'self.references' - remove any references (handles) for items
  # that don't actually exist; and populate 'reference_list' (Array) with
  # the valid reference handles.
  def check_reference_list
    @reference_list = []
    refs = references.split(SPEC_FIELD_DELIMITER)
    if ! refs.nil? && refs.count > 0 then
      refs.each do |r|
        if ref_good(r) then
          @reference_list << r
        end
      end
    end
  end

  private

  pre 'input exists' do |input_filepath| ! input_filepath.nil? end
  def initialize input_filepath
    spec_string = File.read input_filepath
    @input_file_path = input_filepath
    scan_spec spec_string
  end

  # Scan 'spec_string' for settings and use them to set "self"'s fields.
  def scan_spec spec_string
    extract_settings(spec_string)
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
    rem = @setting_for[SINGULAR_REMINDER_KEY]
    if rem then
      rems = @setting_for[REMINDER_KEY]
      @setting_for[REMINDER_KEY] = rems ? "#{rems}, #{rem}" : rem
    end
  end

  FILTERED = {}
  [
    TYPE_KEY, TITLE_KEY, HANDLE_KEY, PRIORITY_KEY,
    DUE_DATE_KEY, GOAL_KEY, EMAIL_KEY, CALENDAR_IDS_KEY,
    PARENT_KEY, EXPIRATION_DATE_KEY, DATE_TIME_KEY, DURATION_KEY,
    LOCATION_KEY, CATEGORIES_KEY, ATTACHMENTS_KEY, REFERENCES_KEY,
    COMMIT_MSG_KEY, REMINDER_KEY
  ].each do |k|
    FILTERED[k] = true
  end

  # Is the value associated with 'key' to be filtered/cleaned?
  def is_filtered key
    FILTERED[key]
  end

  # Extract the settings implied in `spec_string' and use them to set
  # "self"'s fields.
  def extract_settings spec_string
    split_expr = '('
    [TYPE_KEY, TITLE_KEY, DESCRIPTION_KEY, HANDLE_KEY, PRIORITY_KEY,
    DUE_DATE_KEY, GOAL_KEY, EMAIL_KEY, CALENDAR_IDS_KEY, COMMENT_KEY,
    PARENT_KEY, EXPIRATION_DATE_KEY, DATE_TIME_KEY, DURATION_KEY,
    LOCATION_KEY, CATEGORIES_KEY, ATTACHMENTS_KEY, REFERENCES_KEY,
    COMMIT_MSG_KEY].each do |key|
      split_expr += '^' + key + ':[ \t]*|'
    end
    split_expr += '^' + REMINDER_EXPR + ':[ \t]*|^' + START_EXPR + ':[ \t]*)'
    split_regex = Regexp.new(split_expr)
    components = spec_string.split(split_regex, -1)
    if components.length > 0 and components[0] == "" then
      components.shift  # Remove useless empty first element.
    end
    @setting_for = {}
    if not components.empty? and components.length % 2 == 0 then
      (0 .. components.length - 1).step(2) do |i|
        rawkey = components[i]
        key = standardized_key(rawkey.sub(/: *\n?/, ""))
        if is_filtered key then
          value = stripped_of_comments components[i + 1]
        else
          value = multiline_field(components[i + 1])
        end
        if
          (key =~ /#{DESCRIPTION_KEY}/ || key =~ /#{COMMENT_KEY}/) &&
            rawkey =~ /\n/
        then
          value = "\n" + value  # Honor the specified starting newline
        end
        if key == HANDLE_KEY then
          value = value.sub(/(?m:\n.*)/, "")
        end
        @setting_for[key] = value.chomp("")
      end
    end
    standardize_values
  end

  # `s' stripped of lines starthing with '#'
  def stripped_of_comments s
    s.gsub(/^#.*/, "")
  end

  # The multi-line field of type String extracted from 's', ended by
  # 'MULTILINE_FIELD_END_EXPR' (with newlines preserved)
  pre 's is a string' do |s| ! s.nil? && s.is_a?(String) end
  def multiline_field s
    result = ""
    lines = s.split("\n")
    lines.each do |l|
      if MULTILINE_FIELD_END_STRING == l then
        break
      else
        result += "#{l}\n"
      end
    end
    result
  end

  def ref_good(ref_handle)
    # If there's a 'database', simply query it.
    if ! database.nil? then
      result = database[ref_handle] != nil
    else
      if existing_targets.nil? then
        result = false
      else
        # Otherwise, see if it's in the "existing_targets" "hash".
        result = existing_targets.has_key?(ref_handle)
      end
    end
    result
  end

end
