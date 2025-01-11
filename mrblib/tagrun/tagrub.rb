module TagRun
  class Writer
    def initialize
      @content = ""
    end

#    def compose(&blk)
#      result = ""
#
#      if block_given?
#        result = yield
#      end
#
#      if (result.is_a?(Array))
#        @content = result.join
#      else
#        @content = result
#      end
#      @content
#    end
    
    def partial(content)
      @content << content
      ""
    end

    def render
      if(@content == "")
        render_view
      end
      @content
    end

    def content
      @content
    end

    def content=(data)
      @content=data
    end

    # subclass to override this one to popularize @content
    def render_view
    end

    # accessory methods to use in #render_view
    # def render_view
    #   html_ do
    #     head_ do
    #       title_ "This is a title"
    #     end
    #     body_ do
    #       p_ "This is a paragraph"
    #     end
    #   end
    # end
    @@double_tags = %w[html body head title]  

    @@single_tags = %w[meta link]
   
    @@double_tags.each do |element|
      define_method("#{element}_".downcase) do |content=nil, **attrs, &blk|
        @content << begin_tag(element, **attrs)
        result = ""
        if (blk)
          result = blk.call
        elsif (content)
          result = content
        end
        if (result)
          @content << result
        end
        @content << end_tag(element)
        "" ## do not return content
      end
    end

    @@single_tags.each do |element|
      define_method("#{element}_".downcase) do |**attrs|
        @content << single_tag(element, **attrs)
        "" ## do not return content
      end
    end

    # These methods do not modify @content
    def attributes_to_string(**attrs)
      s = attrs.collect do |k, v|
        " #{k}=\"#{v}\"" # Need to escape
      end.join
    end

    def begin_tag(tag_name, **attrs)
      s = attributes_to_string(**attrs)

      return "<#{tag_name}#{s}>"
    end

    def end_tag(tag_name)
      return "</#{tag_name}>"
    end

    def single_tag(tag_name, **attrs)
      s = attributes_to_string(**attrs)

      return "<#{tag_name}#{s}/>"
    end

    def tag_for(tag_name, content=nil, **attrs)
      return "#{begin_tag(tag_name, **attrs)}#{content}#{end_tag(tag_name)}"
    end

    def p_(content = nil, **attrs, &blk)
      tag_for("p", block_given? ? yield : content, **attrs)
    end
  end

end
