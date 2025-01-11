##
## TagRun Test
##

#s = <<-HEREDOC
#   <html>
#     <head></head>
#       <meta charset="UTF-8">
#       <title>redbean-mruby</title>
#       <meta name="viewport" content="width=device-width, initial-scale=1">
#       <link id="theme-link" rel="stylesheet" type="text/css" href="/app/assets/combined.min.css">
#       <link id="skin-link" rel="stylesheet" type="text/css" href="/app/assets/skins/default.css">
#     <body>
#       <p>This is text</p>
#       <hr/>
#     </body>
#   </html>
#HEREDOC

class TestHead < TagRun::Writer
  def render_view
    head_ do
      title_ "ABC"
    end
  end
end

class TestBody < TagRun::Writer
  def render_view
    body_ do
      p_ "123"
    end
  end
end

class TestHtml < TagRun::Writer
  head = TestHead.new
  body = TestBody.new

  def render_view
    html_ do
      partial TestHead.new.render
      partial TestBody.new.render
    end
  end
end

class TestAttributes < TagRun::Writer
  def render_view
    head_ do
      title_ "ABC", class: 'title'
    end
  end
end

class TestMeta < TagRun::Writer
  def render_view
    head_ do
      meta_ charset: 'UTF-8'
      title_ "ABC", class: 'title'
    end
  end
end

assert("TagRun#meta") do
  t = TestMeta.new
  assert_equal("<head><meta charset=\"UTF-8\"/><title class=\"title\">ABC</title></head>", t.render)
end

assert("TagRun#attributes") do
  t = TestAttributes.new
  assert_equal("<head><title class=\"title\">ABC</title></head>", t.render)
end


assert("TagRun#head body") do
  t = TestHtml.new
  assert_equal("<html><head><title>ABC</title></head><body><p>123</p></body></html>", t.render)
end

assert("TagRun#head body") do
  t = TagRun::Writer.new
  t.html_ do
    t.head_ do
    end
    t.body_ do
    end
  end
  assert_equal("<html><head></head><body></body></html>", t.content)
end

assert("TagRun#head") do
  t = TagRun::Writer.new
  t.html_ do
    t.head_ do
      t.title_ "ABC"
    end
  end
  assert_equal("<html><head><title>ABC</title></head></html>", t.content)
end

assert("TagRun#title content") do
  t = TagRun::Writer.new
  t.html_ do
    t.title_ "ABC"
  end

  assert_equal("<html><title>ABC</title></html>", t.content)
end

assert("TagRun#title") do
  t = TagRun::Writer.new
  t.html_ do
    t.title_
  end
  assert_equal("<html><title></title></html>", t.content)
end

assert("TagRun#p attributes") do
  t = TagRun::Writer.new
  result = t.p_("ABC", class: "enhanced")
  assert_equal("<p class=\"enhanced\">ABC</p>", result)
end

assert("TagRun#p") do
  t = TagRun::Writer.new
  result = [1,2,3].collect do |x|
    t.p_ x
  end
  assert_equal("<p>1</p><p>2</p><p>3</p>", result.join)
end

assert("TagRun#p block") do
  t = TagRun::Writer.new
  result = [1,2,3].collect do |x|
    t.p_ do
      x
    end
  end
  assert_equal("<p>1</p><p>2</p><p>3</p>", result.join)
end

assert("TagRun#html") do
  t = TagRun::Writer.new
  t.html_ 
  result = t.content
  assert_equal("<html></html>", result)
end

#assert("TagRun#") do
#  t = TagRun::Writer.new
#  result = t.compose do
#    "html"
#  end
#  assert_equal("html", result)
#end
