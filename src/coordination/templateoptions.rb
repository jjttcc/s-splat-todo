require 'ruby_contracts'
require 'debug/session'

class TemplateOptions
  include SpecTools, ErrorTools
  include Contracts::DSL

  public

  attr_reader :type, :categories, :description, :email, :handle, :location,
    :time, :parent, :title, :calendar_ids, :duration, :priority,
    :references, :attachments, :appended_description
  # git-commit message - i.e., not STodoTarget attribute:
  attr_reader :commit_message

  # query: Is a parse error to be treated as fatal - i.e., causes an
  # exception to be raised?
  attr_reader :parse_error_is_fatal

  protected

  attr_accessor :argument_array
  attr_writer :parse_error_is_fatal

  private

  DEFAULT_TYPE=APPOINTMENT

  post 'arg_array set' do |r, aa|
    implies(! aa.nil?, self.argument_array == aa)
  end
  post 'peif set' do |r, a1, peif_arg|
    implies(! peif_arg.nil?, self.parse_error_is_fatal == peif_arg)
  end
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
  end

  def process_options
    i = 0
    catf, descf, adescf, emf, hndf, locf, parf, titf, cif, durf, ief, oef,
      timf, prif, reff, atf, cmm = 'c', 'd', 'ad', 'e', 'h', 'l', 'p', 't',
        'ci', 'du', 'ie', 'oe', 'ti', 'pr', 'r', 'at', 'm'
    while i < self.argument_array.length do
      case self.argument_array[i]
      when /^-#{catf}\b/
        cats = next_arg(i + 1, catf, true); i += cats.length
        @categories = cats.join(SPEC_FIELD_JOINER)
      when /^-#{descf}\b/
        @description = next_arg(i + 1, descf)[0]; i += 1
      when /^-#{adescf}\b/
        @appended_description = next_arg(i + 1, descf)[0]; i += 1
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
      when /^-#{reff}\b/
        refs = next_arg(i + 1, reff, true); i += refs.length
        @references = refs.join(SPEC_FIELD_JOINER)
      when /^-#{atf}\b/
        attchmts = next_arg(i + 1, atf, true); i += attchmts.length
        @attachments = attchmts.join(SPEC_FIELD_JOINER)
      when /^-#{cmm}\b/
        @commit_message = next_arg(i + 1, cmm)[0]; i += 1
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
    @categories = nil
    @description = nil
    @appended_description = nil
    @email = nil
    @handle = nil
    @location = nil
    @parent = nil
    @title = nil
    @calendar_ids = nil
    @duration = nil
    @time = nil
    @priority = nil
    @main_email = nil
    @initial_email = nil
    @ongoing_email = nil
    @references = nil
    @attachments = nil
  end

  # Scan the option-arguments in 'argument_array', starting at index 'i',
  # and stopping at i+n where 'argument_array[i+n]' starts with "-" (i.e.,
  # holds the next set of option-arguments).
  # Return the result as an array containing each argument found.
  pre 'i: good-int' do |i| ! i.nil? && i.is_a?(Integer) && i >= 0  end
  pre 'i: good-flag' do |i, flag|
    ! flag.nil? && flag.is_a?(String) && ! flag.empty?
  end
  post 'result: array' do |result| ! result.nil? && result.is_a?(Array) end
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
    @email = ''; emails = nil
    if ! @main_email.nil? then
      emails = @main_email.split(SPEC_FIELD_DELIMITER)
    end
    if ! @initial_email.nil? then
      emails ||= []
      emails += @initial_email.split(SPEC_FIELD_DELIMITER).map do |e|
        e + INITIAL_EMAIL_TAG
      end
    end
    if ! @ongoing_email.nil? then
      emails ||= []
      emails += @ongoing_email.split(SPEC_FIELD_DELIMITER).map do |e|
        e + ONGOING_EMAIL_TAG
      end
    end
    if emails then
      @email = emails.join(SPEC_FIELD_JOINER)
    else
      emails = Configuration.instance.default_email
      if emails && ! emails.empty? then
        @email = emails
      end
    end
  end

end
