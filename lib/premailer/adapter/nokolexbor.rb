# frozen_string_literal: true

require 'nokolexbor'

# Modified from Premailer::Adapter::Nokogiri
# Premailer license still applies:
# https://github.com/premailer/premailer/blob/master/LICENSE.md

class Premailer
  module Adapter
    module Nokolexbor
      include AdapterHelper::RgbToHex

      # Merge CSS into the HTML document.
      #
      # @return [String] an HTML.
      def to_inline_css
        doc = @processed_doc
        @unmergable_rules = CssParser::Parser.new

        # Give all styles already in style attributes a specificity of 1000
        # per http://www.w3.org/TR/CSS21/cascade.html#specificity
        doc.css("[style]").each do |el|
          el['style'] = '[SPEC=1000[' + el['style'] + ']]'
        end

        # Iterate through the rules and merge them into the HTML
        @css_parser.each_rule_set(:all) do |rule_set, media_types|
          declaration = declarations_to_s(rule_set)

          if Premailer.is_media_query?(media_types)
            @unmergable_rules.add_rule_set!(CssParser::RuleSet.new(rule_set.selectors.join(','), declaration), media_types)
            next
          end

          rule_set.selectors.each do |selector|
            if selector =~ Premailer::RE_UNMERGABLE_SELECTORS
              @unmergable_rules.add_rule_set!(CssParser::RuleSet.new(selector, declaration))
              next
            end

            # Save un-mergable rules separately
            selector.gsub!(/:link([\s]*)+/i) { |m| $1 }

            # Convert element names to lower case
            selector.gsub!(/([\s]|^)([\w]+)/) { |m| $1.to_s + $2.to_s.downcase }

            specificity = rule_set.specificity || CssParser.calculate_specificity(selector)

            if @options[:preserve_reset] && selector =~ Premailer::RE_RESET_SELECTORS
              # This is in place to preserve the MailChimp CSS reset: http://github.com/mailchimp/Email-Blueprints/
              @unmergable_rules.add_rule_set!(CssParser::RuleSet.new(selector, declaration))
            end

            # Change single ID CSS selectors into xpath so that we can match more
            # than one element.  Added to work around dodgy generated code.
            selector.gsub!(/\A\#([\w_\-]+)\Z/, '[id=\1]')

            begin
              doc.css(selector).each do |el|
                if el.element? && el.name != 'head' && el.parent.name != 'head'
                  # Add a style attribute or append to the existing one
                  el['style'] = (el['style'] || '') + " [SPEC=#{specificity}[#{declaration}]]"
                end
              end
            rescue ::Nokolexbor::LexborError, RuntimeError, ArgumentError
              $stderr.puts "CSS syntax error with selector: #{selector}" if @options[:verbose]
              next
            end
          end
        end

        # Remove script tags
        doc.css("script").remove if @options[:remove_scripts]

        # Read STYLE attributes and perform folding
        doc.css("[style]").each do |el|
          declarations = el['style'].scan(/\[SPEC\=([\d]+)\[(.[^\]\]]*)\]\]/).map! do |declaration|
            [declaration[1].to_s, declaration[0].to_i]
          end

          el['style'] = begin
            case declarations.length
            when 0
              ''
            when 1
              declarations[0][0]
            else
              declarations.map! do |declaration|
                CssParser::RuleSet.new(nil, *declaration)
              rescue ArgumentError
                raise if @options[:rule_set_exceptions]
              end

              declarations.compact!

              declarations_to_s(CssParser.merge(declarations))
            end
          end
        end

        doc = write_unmergable_css_rules(doc, @unmergable_rules) unless @options[:drop_unmergeable_css_rules]

        if @options[:remove_classes] or @options[:remove_comments]
          doc.traverse do |el|
            if el.comment? and @options[:remove_comments]
              el.remove
            elsif el.element?
              el.remove_attribute('class') if @options[:remove_classes]
            end
          end
        end

        if @options[:remove_ids]
          # find all anchor's targets and hash them
          targets = {}

          doc.css("a[href^='#']").each do |el|
            target = el['href'][1..-1]

            next if targets.include?(target)

            digest = Digest::SHA256.hexdigest(target)
            targets[target] = digest
            el['href'] = "#" + digest
          end

          # hash ids that are links target, delete others
          doc.css("[id]").each do |el|
            id = el['id']

            if targets.include?(id)
              el.set_attribute('id', targets[id])
            else
              el.remove_attribute('id')
            end
          end
        end

        if @options[:reset_contenteditable]
          doc.css('[contenteditable]').each do |el|
            el.remove_attribute('contenteditable')
          end
        end

        @processed_doc = doc
        @processed_doc.to_html()
      end

      # Create a <tt>style</tt> element with un-mergable rules (e.g. <tt>:hover</tt>)
      # and write it into the <tt>head</tt>.
      #
      # <tt>doc</tt> is an Nokolexbor document and <tt>unmergable_css_rules</tt> is a Css::RuleSet.
      #
      # @return [::Nokolexbor::Document] a document.
      def write_unmergable_css_rules(doc, unmergable_rules)
        styles = parser_to_s(unmergable_rules)

        unless styles.empty?
          style_tag = ::Nokolexbor::Node.new("style", doc)
          style_tag.content = styles

          head = doc.at_css('head')

          if head
            head.add_child(style_tag)
          else
            (doc.root || doc).prepend_child(style_tag)
          end
        end

        doc
      end

      # Converts the HTML document to a format suitable for plain-text e-mail.
      #
      # If present, uses the <body> element as its base; otherwise uses the whole document.
      #
      # @return [String] a plain text.
      def to_plain_text
        html_src = @doc.at_css("body")&.inner_html
        html_src = @doc.to_html if html_src.nil? || html_src.empty?
        convert_to_text(html_src, @options[:line_length], @html_encoding)
      end

      # Gets the original HTML as a string.
      # @return [String] HTML.
      def to_s
        @doc.to_html
      end

      # Load the HTML file and convert it into an Nokogiri document.
      #
      # @return [::Nokolexbor::Document] a document.
      def load_html(input)
        return input if input.is_a?(::Nokolexbor::Node)

        if @options[:with_html_string] or @options[:inline] or input.respond_to?(:read)
          thing = input
        elsif @is_local_file
          @base_dir = File.dirname(input)
          thing = File.open(input, 'r')
        else
          thing = URI.open(input)
        end

        if thing.respond_to?(:read)
          thing = thing.read
        end

        return unless thing

        # Handle HTML entities
        if @options[:replace_html_entities] == true and thing.is_a?(String)
          HTML_ENTITIES.map do |entity, replacement|
            thing.gsub! entity, replacement
          end
        end

        ::Nokolexbor::HTML(thing)
      end

      private

      def declarations_to_s(rule_set)
        out = []

        rule_set.each_declaration do |prop, value, important|
          importance = important ? ' !important' : ''
          out << "#{prop}:#{value}#{importance};"
        end

        out.join
      end

      def ruleset_to_s(rule_set)
        "#{rule_set.selectors.join(',')}{#{declarations_to_s(rule_set)}}"
      end

      def parser_to_s(parser)
        out = []

        parser.each_rule_set(:all) do |rule_set, media_types|
          media_block = !media_types.include?(:all)
          rules = ruleset_to_s(rule_set)

          if media_block
            media_types.each do |media_type|
              out << "@media #{media_type}{#{rules}}"
            end
          else
            out << rules
          end
        end

        out.join
      end
    end
  end
end 
