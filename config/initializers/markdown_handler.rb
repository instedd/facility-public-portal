module MarkdownHandler
  def self.erb
    @erb ||= ActionView::Template.registered_template_handler(:erb)
  end

  def self.call(template)
    compiled_source = erb.call(template)
    "Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(with_toc_data: true), no_intra_emphasis: true, autolink: true, smarty: true, tables: true, fenced_code_blocks: true, disable_indented_code_blocks: true).render(begin;#{compiled_source};end).html_safe"
  end
end

ActionView::Template.register_template_handler :md, MarkdownHandler
