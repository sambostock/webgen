# -*- encoding: utf-8 -*-

require 'webgen/test_helper'
require 'webgen/content_processor/blocks'
require 'webgen/context'

class TestBlocks < Minitest::Test

  include Webgen::TestHelper

  def test_static_call_and_render_block
    setup_website
    @website.ext.content_processor = Webgen::ContentProcessor.new
    @website.ext.content_processor.register('Blocks')
    @website.ext.content_processor.register('Erb')
    obj = Webgen::ContentProcessor::Blocks

    root = Webgen::Node.new(Webgen::Tree.new(@website).dummy_root, '/', '/')
    node = RenderNode.new("--- name:content pipeline:erb\ndata\n--- name:other\nother",
                          root, 'test', 'test')
    dnode = RenderNode.new("--- name:content pipeline:erb\n<%= context.dest_node.alcn %>",
                           root, 'dtest', 'dtest')
    template = RenderNode.new("--- name:content pipeline:blocks\nbefore<webgen:block name='content' />after",
                              root, 'template', 'template')

    context = Webgen::Context.new(@website)

    context[:chain] = [node]
    context.content = '<webgen:block name="content" /><webgen:block name="content" chain="template;test" />'
    obj.call(context)
    assert_equal('databeforedataafter', context.content)

    context.content = '<webgen:block name="content" node="next" /><webgen:block name="content" chain="template;test" />'
    obj.call(context)
    assert_equal('databeforedataafter', context.content)

    context.content = "\nsadfasdf<webgen:block name='nothing'/>"
    assert_error_on_line(Webgen::RenderError, 2) { obj.call(context) }

    context.content = '<webgen:block name="content" />'
    context[:chain] = [node, template, node]
    obj.call(context)
    assert_equal('beforedataafter', context.content)

    # Test correctly set dest_node
    context[:chain] = [node]
    context.content = '<webgen:block name="content" chain="dtest" />'
    obj.call(context)
    assert_equal('/test', context.content)

    context.content = '<webgen:block name="content" chain="dtest" />'
    assert_equal('/test', obj.render_block(context, :chain => [dnode], :name => 'content'))

    context.content = '<webgen:block name="content" chain="dtest" />'
    context[:dest_node] = dnode
    assert_equal('/dtest', obj.render_block(context, :chain => [dnode], :name => 'content'))
    context[:dest_node] = nil

    # Test options "node" and "notfound"
    context[:chain] = [node, template, node]

    context.content = 'bef<webgen:block name="other" chain="template;test" notfound="ignore" />aft'
    obj.call(context)
    assert_equal('befaft', context.content)

    context.content = '<webgen:block name="other" chain="template" node="first" />'
    assert_error_on_line(Webgen::RenderError, 1) { obj.call(context) }

    context.content = '<webgen:block name="other" chain="template;test" node="first" />'
    obj.call(context)
    assert_equal('other', context.content)

    context.content = '<webgen:block name="other" chain="test" node="first" />'
    obj.call(context)
    assert_equal('other', context.content)

    context.content = '<webgen:block name="invalid" node="first" notfound="ignore" /><webgen:block name="content" />'
    obj.call(context)
    assert_equal('beforedataafter', context.content)

    context[:chain] = [node, template]
    context.content = '<webgen:block name="other" node="current" />'
    obj.call(context)
    assert_equal('other', context.content)

    context.content = '<webgen:block name="other" node="current" chain="template"/>'
    obj.call(context)
    assert_equal('other', context.content)

    assert_equal('other', obj.render_block(context, :chain => [template], :name => 'other', :node => 'current'))
    assert_equal('beforedataafter', obj.render_block(context, :chain => [template, node], :name => 'content', :node => 'first'))
  end

end
