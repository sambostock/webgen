# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'ostruct'
require 'tmpdir'
require 'stringio'
require 'fileutils'
require 'webgen/logger'

require 'webgen/blackboard'
require 'webgen/cache'
require 'webgen/context'
require 'webgen/page'
require 'webgen/error'
require 'webgen/tree'
require 'webgen/node'
require 'webgen/path_handler/page_utils'
require 'webgen/utils'

module Webgen

  module TestHelper

    # A special subclass of Webgen::Node that is used in testing when a "renderable" node is needed,
    # ie. one that has the necessary info set to be processed via Webgen::PathHandler::PageUtils.
    class RenderNode < Webgen::PathHandler::PageUtils::Node

      def initialize(page_data, parent, cn, dest_path, meta_info = {})
        super(parent, cn, dest_path, meta_info)
        page = Webgen::Page.from_data(page_data)
        self.node_info[:blocks] = page.blocks
        self.node_info[:path_handler] = self
        self.meta_info.update(page.meta_info)
      end

      def template_chain
        [self]
      end

    end


    # Fails if the given block does not raise error_class and the error is not on the line.
    def assert_error_on_line(error_class, line)
      begin
        yield
      rescue error_class => e
        assert_equal(line, (e.respond_to?(:line) ? e.line : Webgen::Error.error_line(e)))
      else
        fail "No exception raised though #{error_class} expected"
      end
    end

    # Fails if the log string is not empty.
    #
    # Uses the StringIO @logio if no other StringIO is given.
    def assert_nothing_logged(io = @logio)
      assert_equal('', io.string)
    end

    # Fails if the log string does not match the regular expression.
    #
    # Uses the StringIO @logio if no other StringIO is given and resets the log string after the
    # check.
    def assert_log_match(reg, io = @logio)
      assert_match(reg, io.string)
      @logio.string = ''
    end

    # Creates a basic stub website that is accessible via @website with the following methods:
    #
    # [@website.config]
    #   The given config object or {} if none specified
    #
    # [@website.directory]
    #   Set to a non-existent temporary directory
    #
    # [@website.tmpdir]
    #   Set to @website.directory/tmp
    #
    # [@website.ext]
    #   OpenStruct instance. The accessor +item_tracker+ is set to an object that responds to +add+.
    #
    # [@website.blackboard]
    #   A Webgen::Blackboard instance
    #
    # [@website.logger]
    #   Webgen::Logger instance with a StringIO as target. The StringIO target is also available
    #   via @logio.
    #
    # [@website.tree]
    #   Webgen::Tree instance
    def setup_website(config = {})
      @website = OpenStruct.new
      @website.config = config
      @website.directory = Dir::Tmpname.create("test-webgen-website") {|path| raise Errno::EEXIST if File.directory?(path)}
      @website.define_singleton_method(:tmpdir) do |path='', create=false|
        tmp = File.join(self.directory, 'tmp')
        FileUtils.mkdir_p(tmp) if create
        File.join(tmp, path)
      end
      @website.ext = OpenStruct.new
      @website.blackboard = Webgen::Blackboard.new
      @website.cache = Webgen::Cache.new
      @logio = StringIO.new
      @website.logger = Webgen::Logger.new(@logio)
      @website.tree = Webgen::Tree.new(@website)
      @website.ext.item_tracker = Object.new
      @website.ext.item_tracker.define_singleton_method(:add) {|*args|}
    end

    # Adds the following nodes (showing alcn=dest_path, title, other meta info) to the tree which
    # has to be empty:
    #
    #   /
    #   /file.en.html            'file en' sort_info=3
    #   /file.en.html#frag       'frag'
    #   /file.en.html#nested     'fragnested' routing_path="/routed.html"
    #   /file.de.html            'file de' sort_info=5
    #   /file.de.html#frag       'frag'
    #   /other.html              'other'
    #   /other.en.html           'other en'
    #   /german.de.html          'german' dest_path='/german.other.html'
    #   /dir/                    'dir'
    #   /dir/subfile.html        'subfile'
    #   /dir/subfile.html#frag   'frag'
    #   /dir/dir/                'dir'
    #   /dir/dir/file.html       'file'
    #   /dir2/                   'dir2' proxy_path='index.html'
    #   /dir2/index.en.html      'index en' routed_title='routed en' link_attrs={'class' => 'help'}
    #   /dir2/index.de.html      'index de' routed_title='routed de'
    def setup_default_nodes(tree, klass = Webgen::Node)
      root = klass.new(tree.dummy_root, '/', '/')

      file_en = klass.new(root, 'file.html', '/file.en.html', {'lang' => 'en', 'title' => 'file en', 'sort_info' => 3})
      frag_en = klass.new(file_en, '#frag', '/file.en.html#frag', {'title' => 'frag'})
      klass.new(frag_en, '#nested', '/file.en.html#nested', {'title' => 'fragnested', 'routing_path' => '/routed.html'})
      file_de = klass.new(root, 'file.html', '/file.de.html', {'lang' => 'de', 'title' => 'file de', 'sort_info' => 5})
      klass.new(file_de, '#frag', '/file.de.html#frag', {'title' => 'frag'})

      klass.new(root, 'other.html', '/other.html', {'title' => 'other'})
      klass.new(root, 'other.html', '/other.en.html', {'lang' => 'en', 'title' => 'other en'})

      klass.new(root, 'german.html', '/german.other.html', {'title' => 'german', 'lang' => 'de'})

      dir = klass.new(root, 'dir/', '/dir/', {'title' => 'dir'})
      dir_file = klass.new(dir, 'subfile.html', '/dir/subfile.html', {'title' => 'subfile'})
      klass.new(dir_file, '#frag', '/dir/subfile.html#frag', {'title' => 'frag'})
      dir_dir = klass.new(dir, 'dir/' , '/dir/dir/', {'title' => 'dir'})
      klass.new(dir_dir, 'file.html', '/dir/dir/file.html', {'title' => 'file'})

      dir2 = klass.new(root, 'dir2/', '/dir2/', {'proxy_path' => 'index.html', 'title' => 'dir2'})
      klass.new(dir2, 'index.html', '/dir2/index.en.html',
                       {'lang' => 'en', 'routed_title' => 'routed', 'title' => 'index en', 'link_attrs' => {'class'=>'help'}})
      klass.new(dir2, 'index.html', '/dir2/index.de.html',
                       {'lang' => 'de', 'routed_title' => 'routed de', 'title' => 'index de'})
    end

    # Creates a Webgen::Context object that is returned and accessible via @context.
    #
    # The needed website object is created using #setup_website and the :chain is set to a mock
    # node that responds to :alcn with '/test'.
    def setup_context
      setup_website
      node = Object.new
      node.define_singleton_method(:alcn) { '/test' }
      @context = Webgen::Context.new(@website, :chain => [node], :doit => 'hallo')
    end

    # Creates and returns a RenderNode /tag.template using the default tag template.
    def setup_tag_template(root)
      template_data = File.read(File.join(Webgen::Utils.data_dir, 'passive_sources', 'templates', 'tag.template'))
      RenderNode.new(template_data, root, 'tag.template', '/tag.template')
    end

  end

end
