require 'webgen/websiteaccess'
require 'webgen/loggable'
require 'webgen/path'

module Webgen

  class Node

    include WebsiteAccess
    include Loggable

    # The parent node.
    attr_reader :parent

    # The children of this node.
    attr_reader :children

    # The path of this node.
    attr_reader :path

    # The absolute path of this node.
    attr_reader :absolute_path

    # The tree of this node.
    attr_reader :tree

    # The canonical name of this node.
    attr_reader :cn

    # The localized canonical name of this node.
    attr_reader :lcn

    # The absolute localized canonical name of this node.
    attr_reader :absolute_lcn

    # The language of this node.
    attr_reader :lang

    # Meta information associated with the node.
    attr_reader :meta_info

    # Set by other objects to +true+ if they think the object has changed since the last run. Must
    # not be set to +false+ once it is +true+!
    attr_accessor :dirty

    # Has the node been created or has it been read from the cache?
    attr_accessor :created

    #TODO(doc): Initializes a new Node instance.
    #
    # +parent+ (immutable)::
    #    If this parameter is +nil+, then the new node acts as root. Otherwise, +parent+ has to
    #    be a valid node instance.
    # +path+ (immutable)::
    #    The path for this node. If this node is a directory, the path must have a trailing
    #    slash ('dir/'). If it is a fragment, the hash sign must be the first character of the
    #    path ('#fragment'). A compound path like 'dir/file#fragment' is also allowed as are
    #    absolute paths like 'http://myhost.com/'.
    # +canonical_name+ (immutable)::
    #    The canonical name used for resolving this node. Needs to be of the form 'basename.ext'
    #    or 'basename' where +basename+ does not contain any dots. Also, the 'basename' must not
    #    include a language part! If not set, the +path+ is used as canonical name.
    # +lang+ (immutable)::
    #    The language of the node. If not set, the node is language independent.
    # +meta_info+::
    #    A hash with meta information for the new node.
    #
    # Note: a compound path like 'dir/file' is invalid if the parent node already has a child
    # with path 'dir/'!!! (solution: just create a node with path 'file' and node 'dir/' as parent!)
    def initialize(parent, path, cn = path, meta_info = {})
      @parent = parent
      @path = path.freeze
      @cn = cn.chomp('/').freeze
      @lang = meta_info.delete('lang').freeze
      @meta_info = meta_info
      @children = []
      @dirty = true
      @created = true
      init_rest
    end

    def node_info
      tree.node_info[@absolute_lcn] ||= {}
    end

    # Checks if the node is a directory.
    def is_directory?; @path[-1] == ?/; end

    # Checks if the node is a file.
    def is_file?; !is_directory? && !is_fragment?; end

    # Checks if the node is a fragment.
    def is_fragment?; @path[0] == ?# end

    # Returns +true+ if the node has changed since the last webgen run.
    def changed?
      website.blackboard.dispatch_msg(:node_changed?, self) unless @dirty
      @dirty
    end

    # Returns an informative representation of the node.
    def inspect
      "<##{self.class.name}: alcn=#{@absolute_lcn}>"
    end

    private

    # Regexp for matching absolute URLs, ie. URLs with a scheme part (also see RFC1738)
    ABSOLUTE_URL = /^\w[a-zA-Z0-9+.-]*:/

    def init_rest
      @lcn = Path.lcn(@cn, @lang)

      @tree = @parent
      @tree = @tree.parent while !@tree.kind_of?(Tree)

      loc_parent = @parent
      # Handle fragment nodes specially in case they are nested
      loc_parent = loc_parent.parent while is_fragment? && loc_parent.is_fragment?

      @absolute_path = if @path =~ ABSOLUTE_URL
                         @path
                       else
                         (loc_parent == @tree ? '' : loc_parent.absolute_path + @path)
                       end

      @absolute_lcn = (loc_parent == @tree ? '' : loc_parent.absolute_lcn + (loc_parent.is_directory? ? '/' : '') + @lcn)

      if @tree.node_access.has_key?(@absolute_lcn)
        raise "Can't have two nodes with same absolute lcn"
      else
        @tree.node_access[@absolute_lcn] = self
      end

      @parent.children << self unless @parent == @tree
    end

    # Delegates missing methods to a processor. The current node is placed into the argument array as
    # the first argument before the method +name+ is invoked on the processor.
    def method_missing(name, *args, &block)
      if node_info[:processor]
        website.cache.instance(node_info[:processor]).send(name, *([self] + args), &block)
      else
        super
      end
    end

  end

end
