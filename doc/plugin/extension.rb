module OtherPlugins

  class VersionTag < Tags::DefaultTag

    summary "Shows the version number of webgen"
    depends_on 'Tags'

    def initialize
      super
      register_tag( 'version' )
    end

    def process_tag( tag, node, refNode )
      Webgen::VERSION.join( '.' )
    end

  end

  class DescribeTag < Tags::DefaultTag

    summary "Shows options for the specified file handler"
    add_param 'plugin', nil, 'The plugin which should be described'
    set_mandatory 'plugin', true
    depends_on 'Tags'

    def initialize
      super
      @processOutput = false
      register_tag( 'describe' )
    end

    def process_tag( tag, node, refNode )
      filehandler = get_param( 'plugin' )
      self.logger.debug { "Describing tag #{filehandler}" }
      plugin = Webgen::Plugin.config.find {|k,v| v.plugin == filehandler }
      self.logger.warn { "Could not describe plugin '#{filehandler}' as it does not exist" } if plugin.nil?
      ( plugin.nil? ? '' : format_data( plugin[1] ) )
    end

    def format_data( data )
      s = "<table>"
      row = lambda {|desc, value| "<tr style='vertical-align: top'><td style='font-weight:bold'>#{CGI::escapeHTML( desc )}:</td><td>#{value}</td></tr>" }

      [['Plugin Name', 'plugin'], ['Summary', 'summary'], ['Description', 'description']].each do |desc, name|
        s += row[desc, CGI::escapeHTML( data.send( name ) )] if eval( "data.#{name}" )
      end

      s += row['Dependencies', CGI::escapeHTML( data.dependencies.join( ', ') )] if data.dependencies

      unless data.params.nil?
        params = data.params.sort.collect do |k,v|
          "<span style='color: red'>#{v.name}</span>" + \
          ( v.mandatory.nil? \
            ? "&nbsp;=&nbsp;<span style='color: blue'>#{CGI::escapeHTML( v.default.inspect )}</span>" \
            : " (=" + ( v.mandatoryDefault ? "default " : "" ) + "mandatory parameter)" ) + \
          ": #{CGI::escapeHTML( v.description )}"
        end
        s += row['Parameters', params.join( "<br />\n" )]
      end
      s += row['Name of tag', (data.tag == :default ? "Default tag" : data.tag)] if data.tag
      s += row['File extension', data.extension.inspect.gsub(/"/, '')] if data.extension

      # Show all registered handlers
      data.table.keys.find_all {|k| /^registered_/ =~ k.to_s }.each do |k|
        s += row[k.to_s.sub( /^registered_/, '' ).capitalize + " name", data.send( k )]
      end

      s += "</table>"
    end

  end

end