# -*- encoding: utf-8 -*-

require 'tempfile'
require 'webgen/content_processor'

module Webgen
  class ContentProcessor

    # Uses the external +tidy+ program to format the content as valid (X)HTML.
    module Tidy

      # Process the content of +context+ with the +tidy+ program.
      def self.call(context)
        error_file = Tempfile.new('webgen-tidy')
        error_file.close

        `tidy -v 2>&1`
        if $?.exitstatus != 0
          raise Webgen::CommandNotFoundError.new('tidy', self.class.name, context.dest_node)
        end

        cmd = "tidy -q -f #{error_file.path} #{context.website.config['content_processor.tidy.options']}"
        result = IO.popen(cmd, 'r+') do |io|
          io.write(context.content)
          io.close_write
          io.read
        end
        if $?.exitstatus != 0
          File.readlines(error_file.path).each do |line|
            context.website.logger.send($?.exitstatus == 1 ? :warn : :error) do
              "Tidy reported problems for <#{context.dest_node.alcn}>: #{line}"
            end
          end
        end
        context.content = result
        context
      end

    end

  end
end
