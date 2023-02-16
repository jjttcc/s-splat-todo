class TemplateOptions
  include SpecTools, ErrorTools

  public

  attr_reader :type, :categories, :description, :email, :handle, :location,
    :time, :parent, :title, :calendar_ids, :duration, :priority

  # query: Is a parse error to be treated as fatal - i.e., causes an
  # exception to be raised?
  attr_reader :parse_error_is_fatal

  protected

  attr_accessor :argument_array
  attr_writer :parse_error_is_fatal

  private

  DEFAULT_TYPE=APPOINTMENT

  def initialize arg_array = ARGV, parse_error_fatal = false
    self.argument_array = arg_array
    self.parse_error_is_fatal = parse_error_fatal
    init_attributes
    if self.argument_array.length == 0 then
      @type = DEFAULT_TYPE
    else
      process_options
      set_email
    end
    assert_postcondition('self.parse_error_is_fatal is set') {
      self.parse_error_is_fatal == parse_error_fatal
    }
  end

  def process_options
    i = 0
    catf, descf, emf, hndf, locf, parf, titf, cif, durf, ief, oef,
      timf, prif = 'c', 'd', 'e', 'h', 'l', 'p', 't', 'ci', 'du', 'ie',
      'oe', 'ti', 'pr'
    while i < self.argument_array.length do
      case self.argument_array[i]
      when /^-#{catf}\b/
        cats = next_arg(i + 1, catf, true); i += cats.length
        @categories = cats.join(SPEC_FIELD_JOINER)
      when /^-#{descf}\b/
        @description = next_arg(i + 1, descf)[0]; i += 1
      when /^-#{emf}\b/
        emails = next_arg(i + 1, emf, true); i += emails.length
        @main_email = emails.join(SPEC_FIELD_JOINER)
      when /^-#{hndf}\b/
        @handle = next_arg(i + 1, hndf)[0]; i += 1
      when /^-#{locf}\b/
        @location = next_arg(i + 1, locf)[0]; i += 1
      when /^-#{parf}\b/
        @parent = next_arg(i + 1, parf)[0]; i += 1
      when /^-#{titf}\b/
        @title = next_arg(i + 1, titf)[0]; i += 1
      when /^-#{timf}/
        datetime = next_arg(i + 1, timf, true); i += datetime.length
        @time = datetime.join(SPEC_FIELD_JOINER)
      when /^-#{cif}/
        calids = next_arg(i + 1, cif, true); i += calids.length
        @calendar_ids = calids.join(SPEC_FIELD_JOINER)
      when /^-#{prif}/
        @priority = next_arg(i + 1, prif)[0]; i += 1
      when /^-#{durf}/
        @duration = next_arg(i + 1, durf)[0]; i += 1
      when /^-#{ief}/
        emails = next_arg(i + 1, ief, true); i += emails.length
        @initial_email = emails.join(SPEC_FIELD_JOINER)
      when /^-#{oef}/
        emails = next_arg(i + 1, oef, true); i += emails.length
        @ongoing_email = emails.join(SPEC_FIELD_JOINER)
      else
        if @type == nil then
          @type = self.argument_array[i]
        else
          emsg = "Invalid argument: #{self.argument_array[i]}"
          $log.warn emsg
          if self.parse_error_is_fatal then
            raise emsg
          end
        end
      end
      i += 1
    end
  end

  def init_attributes
    @categories = ''
    @description = ''
    @email = ''
    @handle = ''
    @location = ''
    @parent = ''
    @title = ''
    @calendar_ids = ''
    @duration = ''
    @time = ''
    @priority = ''

    @main_email = ''
    @initial_email = ''
    @ongoing_email = ''
  end

  def next_arg(i, flag, multiple_args = false)
    result = [""]
    if i >= self.argument_array.length then
      raise "Missing argument for flag #{flag}"
    else
      result = [self.argument_array[i]]
      j = i + 1
      while j < self.argument_array.length && self.argument_array[j] !~ /^-/ do
        result << self.argument_array[j]
        j += 1
      end
    end
    result
  end

  # Set 'email' from the various "email" attributes.
  def set_email
    emails = @main_email.split(SPEC_FIELD_DELIMITER)
    emails += @initial_email.split(SPEC_FIELD_DELIMITER).map do |e|
      e + INITIAL_EMAIL_TAG
    end
    emails += @ongoing_email.split(SPEC_FIELD_DELIMITER).map do |e|
      e + ONGOING_EMAIL_TAG
    end
    @email = emails.join(SPEC_FIELD_JOINER)
  end

end
