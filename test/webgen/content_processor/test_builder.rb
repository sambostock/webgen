# -*- encoding: utf-8 -*-

require 'minitest/autorun'
require 'helper'
require 'ostruct'
require 'webgen/content_processor/builder'
require 'webgen/context'

class TestBuilder < MiniTest::Unit::TestCase

  include Test::WebgenAssertions

  def test_static_call
    website = MiniTest::Mock.new
    website.expect(:ext, OpenStruct.new)
    node = MiniTest::Mock.new
    node.expect(:alcn, '/test')

    context = Webgen::Context.new(website, :chain => [node])
    cp = Webgen::ContentProcessor::Builder

    context.content = "xml.div(:path => context.node.alcn) { xml.strong('test'); " +
      "context.website; context; context.ref_node; context.dest_node }"
    assert_equal("<div path=\"/test\">\n  <strong>test</strong>\n</div>\n", cp.call(context).content)

    context.content = "xml.div do \n5+5\n+=+6\nend"
    assert_error_on_line(SyntaxError, 3) { cp.call(context) }

    context.content = "xml.div do \n5+5\nunknown\n++6\nend"
    assert_error_on_line(NameError, 3) { cp.call(context) }

  end

end
