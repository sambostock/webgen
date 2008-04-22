require 'webgen/node'

module Webgen

  class Tree

    include WebsiteAccess

    # The dummy root
    attr_reader :dummy_root

    # Direct access to a node via its absolute lcn.
    attr_reader :node_access

    # Processing information for a node.
    attr_reader :node_info

    def initialize
      @node_access = {}
      @node_info = {}
      @dummy_root = Node.new(self, 'dummy/')
    end

    # The root node of the tree.
    def root
      @dummy_root.children.first
    end

    # Delete the node identitied by +node_or_alcn+ from the tree.
    def delete_node(node_or_alcn, delete_dir = false)
      n = node_or_alcn.kind_of?(Node) ? node_or_alcn : node_access[alcn]
      return if n.nil? || n == @dummy_root || (n.is_directory? && !delete_dir)

      n.children.each {|child| delete_node(child)}

      website.blackboard.dispatch_msg(:before_node_deleted, n)
      n.parent.children.delete(n)
      node_access.delete(n.absolute_lcn)
      node_info.delete(n.absolute_lcn)
    end

  end

end
