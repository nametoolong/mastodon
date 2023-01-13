module CSSHelperLexborPatch
  def css_urls_in_doc(doc)
    tags = doc.css('link[rel=stylesheet]:not([data-premailer=ignore])')
    urls = tags.map { |link| link['href'] }
    tags.remove
    urls
  end
end

Premailer::Rails::CSSHelper.prepend(CSSHelperLexborPatch)

class Premailer::Rails::CustomizedPremailer
  def initialize(html)
    @options = Rails.config.merge(with_html_string: true)

    Premailer.send(:include, Adapter.find(@options[:adapter] || Adapter.use))

    doc = load_html(html)
    options = @options.merge(css_string: Premailer::Rails::CSSHelper.css_for_doc(doc))

    super(doc, options)
  end
end
