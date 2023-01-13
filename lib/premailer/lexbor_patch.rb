module PremailerLexborPatch
  def load_css_from_html!
    tags = @doc.css("style:not([data-premailer=ignore])")

    if @options[:include_style_tags]
      tags.each do |tag|
        @css_parser.add_block!(tag.inner_html, :base_uri => @base_url, :base_dir => @base_dir, :only_media_types => [:screen, :handheld])
      end
    end

    tags.remove unless @options[:preserve_styles]
  end

  def convert_inline_links(doc, base_uri)
    base_uri = Addressable::URI.parse(base_uri) unless base_uri.kind_of?(Addressable::URI)

    ['href', 'src', 'background'].each do |attribute|
      doc.css("[#{attribute}]").each do |tag|
        link = tag[attribute]

        # skip links that look like they have merge tags
        # and mailto, ftp, etc...
        if link =~ /^([\%\<\{\#\[]|data:|tel:|file:|sms:|callto:|facetime:|mailto:|ftp:|gopher:|cid:)/i
          next
        end

        begin
          tag[attribute] = Premailer.resolve_link(link, base_uri)
        rescue
          next
        end
      end
    end

    doc.css("[style]").each do |el|
      el['style'] = CssParser.convert_uris(el['style'], base_uri)
    end

    doc
  end

  def check_client_support
    # Premailer's CLIENT_SUPPORT_FILE is 13 years old.
    []
  end
end

Premailer.prepend(PremailerLexborPatch)