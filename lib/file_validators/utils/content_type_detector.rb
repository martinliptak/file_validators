require 'logger'

begin
  require 'cocaine'
rescue LoadError
  puts "file_validators requires 'cocaine' gem as you are using file content type validations in strict mode"
end

module FileValidators
  module Utils

    class ContentTypeDetector
      EMPTY_CONTENT_TYPE = 'inode/x-empty'
      DEFAULT_CONTENT_TYPE = 'application/octet-stream'

      attr_accessor :file_path, :file_name

      def initialize(file_path, file_name)
        @file_path = file_path
        @file_name = file_name
      end

      # content type detection strategy:
      #
      # 1. empty file: returns 'inode/x-empty'
      # 2. nonempty file: if the file is not empty then returns the content type using file command
      # 3. invalid file: file command raises error and returns 'application/octet-stream'

      def detect
        empty_file? ? EMPTY_CONTENT_TYPE : content_type_from_content
      end

      private

      def empty_file?
        File.exists?(file_path) && File.size(file_path) == 0
      end

      def content_type_from_content
        content_type = type_from_file_command

        if FileValidators::Utils::MediaTypeSpoofDetector.new(content_type, file_name).spoofed?
          logger.warn('A file with a spoofed media type has been detected by the file validators.')
        else
          content_type
        end
      end

      def type_from_file_command
        begin
          Cocaine::CommandLine.new('file', '-b --mime-type :file').run(file: @file_path).strip
        rescue Cocaine::CommandLineError => e
          logger.info(e.message)
          DEFAULT_CONTENT_TYPE
        end
      end

      def logger
        Logger.new(STDOUT)
      end
    end

  end
end
