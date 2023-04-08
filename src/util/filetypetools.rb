require 'ruby_contracts'
require 'mediaconfigtools'

# Facilities for working with file types, based on the model implied by the
# UNIX 'file' command
module FileTypeTools
  include Contracts::DSL
  include MediaConfigTools

  public

  # mapping of media types (from this app's viewpoint) to regular
  # expressions designed to match appropriate file types
  @@regexes_for = {
    MSWORD      => [ Regexp.new("application/msword") ],
    MSEXCEL     => [ Regexp.new("application/vnd.ms-excel") ],
    ODFSPREAD   => [
      Regexp.new("application/vnd.oasis.opendocument.spreadsheet")
    ],
    ODFTEXT     => [
      Regexp.new("application/vnd.oasis.opendocument.text")
    ],
    OPENXML     => [ Regexp.new(
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    ],
    ##### [need to fill in remaining executable-file exprs] ####
    EXECUTABLE  => [ Regexp.new("application/x-pie-executable"),
                      Regexp.new("application/x-executable"),
    ],
    PLAIN_TEXT  => [ Regexp.new("text/plain"),
                     Regexp.new("inode/x-empty"),
    ],
    PDF         => [ Regexp.new("application/pdf") ],
    ##### [need to fill in remaining video-format exprs] ####
    VIDEO       => [ Regexp.new("video/mp4"), Regexp.new("video/mpeg")
    ],
    CODE        => [
    ##### [need to fill in remaining programming-language exprs] ####
      Regexp.new("text/x-shellscript"),
      Regexp.new("text/x-ruby;"),
      Regexp.new("text/x-perl"),
    ],
    AUDIO      => [
    ##### [need to fill in remaining audio exprs] ####
      Regexp.new("audio/mpeg"),
      Regexp.new("audio/ogg"),
      Regexp.new("audio/x-m4a"),
    ],
    DIRECTORY  => [
      Regexp.new("inode/directory"),
    ],
  }

  @@file_types = @@regexes_for.keys

  # The "stodo" file type for the specified 'file_type_string', a string
  # obtained from the output of the UNIX "file" command
  pre '' do |fts| ! fts.nil? && ! fts.empty? end
  post 'nil or valid type' do |result|
    result.nil? || @@regexes_for.has_key?(result)
  end
  def file_type_for file_type_string
    result = nil
    @@regexes_for.keys.each do |k|
      regs = @@regexes_for[k]
      regs.each do |r|
        if r.match?(file_type_string) then
          result = k
          break
        end
      end
      if result then
        break
      end
    end
    result
  end

  # Is file-type 'type' that of a directory?
  pre 'type is valid' do |type| ! type.nil? && type.is_a?(Symbol) end
  def is_directory(type)
    type == DIRECTORY
  end

=begin
# some different media types, according to 'file -i':
application/vnd.oasis.opendocument.spreadsheet; charset=binary
application/vnd.ms-excel; charset=binary
application/msword; charset=binary
application/x-pie-executable; charset=binary
application/vnd.openxmlformats-officedocument.spreadsheetml.sheet; charset=binary
text/plain; charset=us-ascii
application/pdf; charset=binary
audio/mpeg; charset=binary
audio/ogg; charset=binary
video/mp4; charset=binary
video/mpeg; charset=binary
text/x-shellscript; charset=us-ascii
Bourne-Again shell script, ASCII text executable
text/x-ruby; charset=us-ascii
text/x-perl; charset=us-ascii
=end
end

=begin
REFERENCES:
https://www.linux.org/threads/supported-libreoffice-files.11348/
open document format (ODF):
https://www.libreoffice.org/discover/what-is-opendocument/#:~:text=LibreOffice%20uses%20the%20OpenDocument%20Format,access%20to%20your%20data%20forever.
office open XML:
http://officeopenxml.com/
=end
