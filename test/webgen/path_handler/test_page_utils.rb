# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/path_handler/page_utils'
require 'webgen/content_processor'
require 'webgen/path'

class TestPageUtils < MiniTest::Unit::TestCase

  include Webgen::TestHelper

  class MyHandler
    include Webgen::PathHandler::PageUtils
  end

  def setup
    @handler = MyHandler.new
  end

  def test_parse_as_page!
    path = Webgen::Path.new('/test.html') { StringIO.new("---\nkey: value\n---\ncontent") }
    blocks = @handler.send(:parse_as_page!, path)
    assert_kind_of(Hash, blocks)
    assert_equal('content', blocks['content'])
    assert_equal('value', path.meta_info['key'])
  end

  def test_render_block
    setup_context
    node = @context.node
    node.expect(:node_info, {:blocks => {'content' => 'mycontent'}})
    @context.node.expect(:meta_info, {})
    @website.ext.content_processor = Webgen::ContentProcessor.new
    @website.ext.item_tracker = MiniTest::Mock.new
    @website.ext.item_tracker.expect(:add, nil, [node, :node_content, node.alcn])

    # invalid block name
    assert_raises(Webgen::RenderError) { @handler.render_block(node, 'unknown', @context) }

    # nothing to render because pipeline is empty
    @handler.render_block(node, 'content', @context)
    assert_equal('mycontent', @context.content)

    # invalid content processor
    assert_raises(Webgen::Error) { @handler.render_block(node, 'content', @context, ['test']) }

    node.meta_info['blocks'] = {'content' => {'pipeline' => ['test']}}
    assert_raises(Webgen::Error) { @handler.render_block(node, 'content', @context) }

    # with content processor
    @website.ext.content_processor.register('test') {|ctx| ctx.content = 'test' + ctx.content; ctx}
    @handler.render_block(node, 'content', @context)
    assert_equal('testmycontent', @context.content)

    @handler.render_block(node, 'content', @context, ['test', 'test'])
    assert_equal('testtestmycontent', @context.content)
  end

end
