pop = PopTags

describe "PopTags", ->
  describe "When rendering a plain text without tags", ->
    it "should display the template", ->
      template = "I am a plain text"
      expect(new pop.Template({template: template}).render({})).toEqual("I am a plain text")

  describe "a tag", ->
    beforeEach ->
      @template = "<h1>Home - <pop:site_title /></h1>"

    describe "with an empty scope", ->
      beforeEach ->
        @content  = {}

      it "should render nothing", ->
        expect(new pop.Template({template: @template}).render(@content)).toEqual("<h1>Home - </h1>")

    describe "with the variable in the scope", ->
      beforeEach ->
        @content = {site_title: "Webpop"}

      it "should replace the tag with the value of the variable", ->
        expect(new pop.Template({template: @template}).render({site_title: "Webpop"})).toEqual("<h1>Home - Webpop</h1>")

  describe "a tag with a nested tag", ->
    beforeEach ->
      @template = "<pop:content><li><pop:title /></li></pop:content>"

    describe "with an array in the scope and variable inside", ->
      beforeEach ->
        @content = {content: [{title: "Hello"},{title: "World"}]}

      it "should repeat the enclosed tag and perform the substitution for each element", ->
        expect(new pop.Template({template: @template}).render(@content)).toEqual("<li>Hello</li><li>World</li>")

    describe "with a function returning an array", ->
      beforeEach ->
        @content =
          content: -> [{title: "Hello"},{title: "World"}]

      it "should repeat the enclosed tags and perform the substitution for each element", ->
        expect(new pop.Template({template: @template}).render(@content)).toEqual("<li>Hello</li><li>World</li>")
      
      it "should handle first and last", ->
        expect(new pop.Template({template: "<pop:content break='li'><pop:first>First</pop:first><pop:last>Last</pop:last> <pop:title/></pop:content>"})
        .render(@content))
        .toEqual("<li>First Hello</li><li>Last World</li>")
      
      it "should handle first and last when the array elements are functions", ->
        @content = {content: -> [{title: "Hello"}, {title: "World"}]}
        expect(new pop.Template({template: "<pop:content break='li'><pop:first>First</pop:first><pop:last>Last</pop:last> <pop:title/></pop:content>"})
        .render(@content))
        .toEqual("<li>First Hello</li><li>Last World</li>")

  describe "with an array of strings", ->
    beforeEach ->
      @content = {titles: ["Hello", "World"]}

    describe "when rendered with no enclosed tags", ->
      beforeEach ->
        @template = '<pop:titles break=", "/>'

      it "should render the strings", ->
        expect(new pop.Template({template: @template}).render(@content)).toEqual("Hello, World")

      it "should handle just one string", ->
          expect(new pop.Template({template: @template}).render({titles: ["Hello"]})).toEqual("Hello")
      
      it "should handle first and last", ->
         expect(new pop.Template({template: '<pop:titles break=", "><pop:first>First</pop:first><pop:last>Last</pop:last> <pop:value/></pop:titles>'})
         .render(@content))
         .toEqual( "First Hello, Last World")
      
      it "should not have first and last outside the collection", ->
         expect(new pop.Template({template: '<pop:titles break=", "/><pop:first>First</pop:first><pop:last>Last</pop:last>'})
         .render(@content))
         .toEqual("Hello, World")
    
    describe "when rendering nested array and pop:first tags", ->
      beforeEach ->
        @template = '<pop:outer><pop:inner><pop:title/></pop:inner>, <pop:first><pop:title/></pop:first></pop:outer>'
        @nested =
          outer: [{
            title: "World",
            inner: [{title: "Hello"}]
          }]
      
      it "should render the strings", ->
        expect(new pop.Template({template: @template})
        .render(@nested))
        .toEqual("Hello, World")

    describe "when rendered with enclosed tags", ->
      beforeEach ->
        @template = '<pop:titles><h2><pop:value /></h2></pop:titles>'

      it "should render the enclosed tags for each string with the string available as value in the scope", ->
        expect(new pop.Template({template: @template})
        .render(@content))
        .toEqual("<h2>Hello</h2><h2>World</h2>")

    describe "when rendered with the repeat=false option", ->
      beforeEach ->
        @template = '<pop:titles repeat="false"><h2><pop:values break=", " /></h2></pop:titles>'

      it "should only render the enclosed tags once and pass the array to the values variable", ->
        expect(new pop.Template({template: this.template})
        .render(@content))
        .toEqual("<h2>Hello, World</h2>")
      
      it "should still respect the no_ tag", ->
        content = {titles: []}
        template = "<pop:titles repeat='false'>Something</pop:titles><pop:no_titles>Hello, World</pop:no_titles>"
        expect(new pop.Template({template: template})
        .render(content))
        .toEqual("Hello, World")

    describe "when using no repeat and skip", ->
      beforeEach ->
        @template = '<pop:titles repeat="false"><pop:values skip="1"><h2><pop:value /></h2></pop:values></pop:titles>'

      it "should only render the enclosed tags once and pass the array to the values variable", ->
        expect(new pop.Template({template: @template})
        .render(@content))
        .toEqual("<h2>World</h2>")

    describe "when using no repeat and limit", ->
      beforeEach ->
        @template = '<pop:titles repeat="false"><pop:values limit="1"><h2><pop:value /></h2></pop:values></pop:titles>'

      it "should only render the enclosed tags once and pass the array to the values variable", ->
        expect(new pop.Template({template: @template})
        .render(@content))
        .toEqual("<h2>Hello</h2>")

    describe "when using no repeat and skip and limit", ->
      beforeEach ->
        @template = '<pop:titles repeat="false"><pop:values skip="1" limit="1"><h2><pop:value /></h2></pop:values></pop:titles>'

      it "should only render the enclosed tags once and pass the array to the values variable", ->
        expect(new pop.Template({template: @template})
        .render(@content))
        .toEqual("<h2>World</h2>")

  describe "with a function returning an array of more complex objects", ->
    beforeEach ->
      @template = '<pop:entries wrap="ul" break="li"><pop:content><h4><pop:title /></h4></pop:content></pop:entries>'
      @content =
        entries: ->
          [
            {"content":{"title":"Raspberry Stripe"}},
            {"content":{"title":"Denim Blue"}},
            {"content":{"title":"Cotton Candy"}}
          ]

    it "should render the enclosed tags for each object", ->
      expect(new pop.Template({template: @template})
      .render(@content))
      .toEqual("<ul><li><h4>Raspberry Stripe</h4></li><li><h4>Denim Blue</h4></li><li><h4>Cotton Candy</h4></li></ul>")

  describe "When rendering a template refering to content from an extension", ->
    beforeEach ->
      @template = "<title><pop:sample_extension:title /></title>"
      sample_extension =
        title: "Hello From Sample Extension"

      @require = (name) ->
        if (name == 'sample_extension') then sample_extension

    it "should require the extension and get the content from there", ->
      expect(new pop.Template({template: @template, require: @require})
      .render({}))
      .toEqual("<title>Hello From Sample Extension</title>")

    describe "with a no tag", ->
      beforeEach ->
        @template = "<title><pop:ext:title>Hello</pop:ext:title><pop:ext:no_title>No title</pop:ext:no_title></title>"
        @require = (name) ->
          if (name == 'ext') then {title: null}

      it "should render the no tag when", ->
        expect(new pop.Template({template: @template, require: @require})
        .render({}))
        .toEqual("<title>No title</title>")

      it "should handle wrap and class on a no tag", ->
        @template = "<pop:ext:title>Hello</pop:ext:title><pop:ext:no_title wrap='p' class='none'>No title</pop:ext:no_title>"
        expect(new pop.Template({template: @template, require: @require})
        .render({}))
        .toEqual("<p class=\"none\">No title</p>")


  describe "When rendering tags within a tag that changes the scope to that of an extension", ->
    beforeEach ->
      @template = "<title><pop:ext:post><pop:title /></pop:ext:post></title>"
      ext =
        post: -> {title: 'Hello'}
      @require = (name) -> if(name == 'ext') then ext

    it "should use the content from the extension", ->
      expect(new pop.Template({template: @template, require: @require})
      .render({}))
      .toEqual("<title>Hello</title>")

  describe "When rendering a template that passes options to a tag", ->
    beforeEach ->
      @content =
        posts: (options) -> {id: i+1} for i in [0...options.limit]

    describe "when double-quoting the option", ->
      beforeEach ->
        @template = "<pop:posts limit=\"3\"><li><pop:id /></li></pop:posts>"

      it "should pass the options to the tag", ->
        expect(new pop.Template({template: @template})
        .render(@content))
        .toEqual("<li>1</li><li>2</li><li>3</li>")

    describe "when single-quoting the option", ->
      beforeEach ->
        @template = "<pop:posts limit='3'><li><pop:id /></li></pop:posts>"

      it "should pass the options to the tag", ->
        expect(new pop.Template({template: @template})
        .render(@content))
        .toEqual("<li>1</li><li>2</li><li>3</li>")
    
    describe "when passing an extension method as the option", ->
      beforeEach ->
        sample_extension = {limit: -> 3}
        @require = (name) -> if (name == 'sample_extension') then sample_extension
        @template = "<pop:posts limit='<pop:sample_extension:limit/>'><li><pop:id /></li></pop:posts>"
      
      it "should call the function and pass the result to the tag", ->
        expect(new pop.Template({template: @template, require: @require})
        .render(@content))
        .toEqual("<li>1</li><li>2</li><li>3</li>")
    
    describe "when passing an extension method as the option to a tag with a html function", ->
      beforeEach ->
        sample_extension =
          name: -> "World!"
        @require = (name) -> if name == 'sample_extension' then sample_extension
        @content =
          greet:
            html: (options) -> "Hello, " + options.name
        @template = "<pop:greet name='<pop:sample_extension:name/>'/>"
      
      it "should call the function and pass the result to the tag", ->
        expect(new pop.Template({template: @template, require: @require})
        .render(@content))
        .toEqual("Hello, World!")

  describe "When rendering a template with default content", ->
    beforeEach ->
      @template = "<pop:something><pop:title default=\"Hello\" /></pop:something>" +
                  "<pop:no_something>No Content</pop:no_something>"

    describe "with no content", ->
      beforeEach -> @content = {}

      it "should render the no_content tag", ->
        expect(new pop.Template({template: @template})
        .render(@content).trim())
        .toEqual("No Content")

    describe "with content but no value for the tag", ->
      beforeEach -> @content = {something: {}}

      it "should render the value of the 'default' attribute", ->
        expect(new pop.Template({template: @template})
        .render(@content).trim())
        .toEqual("Hello")

    describe "when the tempate has a pop tag in the default attribute", ->
      beforeEach ->
        @tempate = "<pop:something default='<pop:something_else />'/>"
        @content = {something_else: "Hello"}

      it "should render the result of evaluating the pop tag", ->
        expect(new pop.Template({template: @tempate})
        .render(@content).trim())
        .toEqual("Hello")

    describe "when the layout is chosen by an pop tag", ->
      beforeEach ->
        @layout = "<h1><pop:region name='main'/></h1>"
        @template = "<pop:layout name='<pop:the_layout/>'/><pop:block region='main'>Hello</pop:block>"
        @content = {the_layout: "layout"}
        @read = (name) => if name == 'layouts/layout' then @layout

      it "should render the right layout", ->
        expect(new pop.Template({template: @template, read: @read})
        .render(@content).trim())
        .toEqual("<h1>Hello</h1>")

   describe "when a region uses wrap and class", ->
     beforeEach ->
       @layout = "<pop:region name='main' wrap='div' class='main'/>"
       @template = "<pop:layout name='<pop:the_layout/>'/><pop:block region='main'>Hello</pop:block>"
       @content = {the_layout: "layout"}
       @read = (name) => if name == 'layouts/layout' then @layout

     it "should render the right layout", ->
       expect(new pop.Template({template: @template, read: @read})
       .render(@content).trim())
       .toEqual('<div class="main">Hello</div>')

    describe "with a no_ tag and an include inside", ->
      beforeEach ->
        @template = "<pop:layout name='outer' /><pop:block region='main'><pop:content><pop:test>Test: <pop:include template='inner' /></pop:test><pop:no_test><pop:include template='inner' /></pop:no_test></pop:content></pop:block>"
        @outer   = "<pop:region name='main' />"
        @inner   = "<h1><pop:title /></h1>"
        @content = {content: {title: "Hello", test: []}}
        @read = (name) =>
          return @inner if name == 'inner'
          return @outer if name == 'layouts/outer'

      it "should render the result of evaluating the pop tag", ->
        expect(new pop.Template({template: @template, read: @read})
        .render(@content).trim())
        .toEqual("<h1>Hello</h1>")

  describe "no content tag inside a collection", ->
    beforeEach ->
      @template = "<pop:something><pop:title /><pop:no_title>No Title </pop:no_title></pop:something>"

    describe "where some has the content and some doesn't", ->
      beforeEach ->
        @content =
          something: [{}, {title: "Yes Title"}]

      it "should render the no_content tag", ->
        expect(new pop.Template({template: @template})
        .render(@content).trim())
        .toEqual("No Title Yes Title")
  
  describe "using lookup on the scope in a tag", ->
    beforeEach ->
      @template = "<pop:content><pop:something><pop:t name='title'/></pop:something></pop:content>"
      @content =
        content: {title: "Hello, World"}
        something: {testing: "Testing"}
        t: (options, enclosed, scope) -> scope.lookup(options.name)
    
    it "should crawl up the scope chain", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("Hello, World")

  describe "When rendering a template with a filter", ->
    beforeEach ->
      @template = "<pop:upcase>hello world</pop:upcase>"
      @content =
        upcase: (options, enclosing) -> enclosing.render().toUpperCase()

    it "should call the filter with the enclosed text", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("HELLO WORLD")

  describe "When rendering a template with a filtered text and substitution", ->
    beforeEach ->
      @template = "<pop:upcase><pop:title /></pop:upcase>"
      @content =
        upcase: (options, enclosing) -> enclosing.render().toUpperCase()
        title: "Hello world"

    it "should let the filter render the enclosed tags and replace them with the result", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("HELLO WORLD")

  describe "a tag with a wrap attribute", ->
    beforeEach ->
      @template = '<pop:title wrap="span" />'
      @content = {title: 'I should be wrapped in a span'}

    it "should wrap the content in the element specified in the attribute", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("<span>I should be wrapped in a span</span>")

  describe "a tag with with a wrap and a class attribute", ->
    beforeEach ->
      @template = '<pop:title wrap="span" class="title"/>'
      @content = {title: 'I should be wrapped in a span'}

    it "should add the class to the wrap element", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("<span class=\"title\">I should be wrapped in a span</span>")

  describe "a tag with a wrap attribute for an empty element", ->
    beforeEach ->
      @template = '<pop:title wrap="span" class="title"/>'
      @content = {}

    it "should not add the wrap element", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("")
    
    it "should not add the wrap element when the value is an empty array", ->
      this.content.title = [];
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("")

    it "should work with repeat false", ->
      @content.title = []
      template = '<pop:title wrap="span" class="title" repeat="false" />'
      expect(new pop.Template({template: template})
      .render(@content).trim())
      .toEqual("")
    
    it "should work with a function returning an empty array", ->
      @content.title = -> []
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("")

  describe "a tag with wrap and break attributes", ->
    beforeEach ->
      @template = '<pop:posts wrap="ul" break="li"><pop:title /></pop:posts>'
      @content = {posts: [{title:'post 1'}, {title: 'post 2'}]}

    it "should wrap the content in the wrap element and wrap each repetition in the break element", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("<ul><li>post 1</li><li>post 2</li></ul>")

  describe "a tag with a break attribute that is not an html tag", ->
    beforeEach ->
      @template = '<pop:posts break=", "><pop:title /></pop:posts>';
      @content = {posts: [{title:'post 1'}, {title: 'post 2'}, {title: 'post 3'}]}

    it "should separate each repetition with the value of the break attribute", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("post 1, post 2, post 3")

    describe "and a last attribute", ->
      beforeEach ->
        @template = '<pop:posts break=", " last=" and "><pop:title /></pop:posts>'

      it "should separate each repetition with the value of the break attribute and the last 2 with the value of the last attribute", ->
        expect(new pop.Template({template: @template})
        .render(@content).trim())
        .toEqual("post 1, post 2 and post 3")

  describe "a tag with a break attribute that is an html5 self-closing tag", ->
    beforeEach ->
      @template = '<pop:posts break="br"><pop:title /></pop:posts>'
      @content = {posts: [{title:'post 1'}, {title: 'post 2'}]}

    it "should separate each repetition with the value of the break attribute", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("post 1<br />post 2")

  describe "a self-closing tag for a boolean element that is true", ->
    beforeEach ->
      @template = '<pop:readmore />'
      @content = {readmore: true}

    it "should render the string 'true'", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("true")

  describe "a self-closing tag for a boolean element that is false", ->
    beforeEach ->
      @template = '<pop:readmore />'
      @content = {readmore: false}

    it "should render the string 'false'", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("false")

  describe "a tag for a boolean element that is true and has enclosed content", ->
    beforeEach ->
      @template = '<pop:readmore>You can read more</pop:readmore>'
      @content = {readmore: true}

    it "should render the enclosed content", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("You can read more")

  describe "a tag for a boolean element that is false and has enclosed content", ->
    beforeEach ->
      @template = '<pop:readmore>You can read more</pop:readmore>'
      @content = {readmore: false}

    it "should render nothing", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("")

  describe "a tag for a boolean element that is false and has default content", ->
    beforeEach ->
      @template = '<pop:readmore default="You cannot read more">You can read more</pop:readmore>'
      @content = {readmore: false}

    it "should render nothing", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("You cannot read more")

  describe "a tag for a string element that is enclosing other tags", ->
    beforeEach ->
      @template = '<pop:title>Title: <pop:title /></pop:title>'
      @content = {title: 'Hello, World!'}

    it "should render the enclosed content", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("Title: Hello, World!")

  describe "a tag for a non-existing element that is enclosing other tags", ->
    beforeEach ->
      @template = '<pop:title>Title: <pop:title /></pop:title>'
      @content = {}

    it "should render nothing", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("")

  describe "a tag for an undefined element", ->
    beforeEach ->
      @template = '<pop:title />'
      title = undefined
      this.content = {title: title}

    it "should render nothing", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("")

  describe "a tag with an undefined html value and a bad toString method", ->
    beforeEach ->
      @template = '<pop:title />'
      title = undefined
      @content = {title: {html: title, toString: -> title }}

    it "should render nothing", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("")

  describe "a tag with an empty html value", ->
    beforeEach ->
      @template = '<pop:title />'
      @content = {title: {html: null}}

    it "should render nothing", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("")

  describe "a tag for an undefined element that is exists further up in the scope", ->
    beforeEach ->
      @template = '<pop:content>Title: <pop:title /></pop:content>'
      Content = ->
      Content.prototype.title = ->
      @content = {title: "Hello, World", content: new Content}

    it "should render nothing", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("Title:")

  describe "a tag for an non existing element that is exists further up in the scoe", ->
    beforeEach ->
      @template = '<pop:content>Title: <pop:title /></pop:content>'
      Content = ->
      @content = {title: "Hello, World", content: new Content}

    it "should render nothing", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("Title: Hello, World")

  describe "a self-closing tag for an object with an html function", ->
    beforeEach ->
      @template = 'Read more: <pop:link text="here" />'
      @content =
        link:
          html: (options) -> "<a href='/slug'>#{options.text}</a>"

    it "should render the result of calling the html function", ->
      expect(new pop.Template({template: @template})
      .render(@content).trim())
      .toEqual("Read more: <a href='/slug'>here</a>")

  describe "an include tag", ->
    beforeEach ->
      @template = '<div><pop:include template="hello-world" /></div>'
      @read = (name) -> if name == 'hello-world' then "Hello <pop:title />" else null
      @content = {title: 'World'};

    it "should include another template into the current one", ->
      expect(new pop.Template({template: @template, read: @read})
      .render(this.content).trim())
      .toEqual("<div>Hello World</div>")

  describe "a template that includes itself", ->
    beforeEach ->
      template = '<ul><pop:files><pop:dir><pop:include template="listing" /></pop:dir><pop:file><li><pop:name/></li></pop:file></pop:files></ul>'
      @read = (name) -> if name == 'listing' then template else null
      @content =
        files: [
          {file: true, name: "test.txt", dir: false}
          {dir: true, files: [
            {file: true, dir: false, name: "/a/test.txt"}
          ]}
        ]

    it "should not go into an endless loop :P", ->
      expect(new pop.Template({name: 'listing', read: @read})
      .render(@content).trim())
      .toEqual("<ul><li>test.txt</li><ul><li>/a/test.txt</li></ul></ul>")

  describe "a template that includes itself and recurses several times", ->
    beforeEach ->
      template = '<ul><pop:files><pop:dir><pop:include template="listing" /></pop:dir><pop:file><li><pop:name/> - <pop:global /></li></pop:file></pop:files></ul>'
      @read = (name) -> if name == 'listing' then template else null
      @content =
        global: -> "I am global!"
        files: [
            {file: true, name: "test.txt", dir: false},
            {dir: true, files: [
              {file: true, dir: false, name: "/a/test.txt"},
              {dir: true, file: false, files: [
                {file: true, dir: false, name: "/a/b/test.txt"}
              ]}
            ]}
          ]

    it "should have access to the global scope", ->
      expect(new pop.Template({name: 'listing', read: @read})
      .render(@content).trim())
      .toEqual("<ul><li>test.txt - I am global!</li><ul><li>/a/test.txt - I am global!</li><ul><li>/a/b/test.txt - I am global!</li></ul></ul></ul>")

  describe "a template with a layout", ->
    beforeEach ->
      layout = '<html><pop:region name="main" /></html>'
      @template = '<pop:layout name="default" /><pop:block region="main"><h1><pop:title /></h1></pop:block>'
      @content  = {title: "Hello, World!"}

      @read = (name) -> if name == 'layouts/default' then layout else null

    it "should replace the regions defined in the layout with the blocks defined in the template", ->
      expect(new pop.Template({template: @template, read: @read})
      .render(@content).trim())
      .toEqual("<html><h1>Hello, World!</h1></html>")

  describe "a template with layout and no block for a region", ->
    beforeEach ->
      layout = '<html><pop:region name="main">Default content for main</pop:region></html>'
      @template = '<pop:layout name="default" />'
      @read = (name) -> if name == 'layouts/default' then layout else null

    it "should render the contents of the region defined in the layout", ->
      expect(new pop.Template({template: @template, read: @read})
      .render({}).trim())
      .toEqual("<html>Default content for main</html>")

  describe "a tag with a dynamic attribute", ->
    beforeEach ->
      @template = '<pop:output value="Hello, <pop:something />" />'
      @content =
        output: (options) -> options.value
        something: 'World!'

    it "should get the attribute with the proper value", ->
      expect(new pop.Template({template: @template})
      .render(@content))
      .toEqual("Hello, World!")

  describe "an include tag with a dynamic template name", ->
    beforeEach ->
      @template = '<div><pop:include template="<pop:template />" /></div>'
      @read = (name) -> if name == 'hello-world' then "Hello <pop:title />" else null
      @content = {title: 'World', template: 'hello-world'}

    it "should include the right template", ->
      expect(new pop.Template({template: @template, read: @read})
      .render(this.content).trim())
      .toEqual("<div>Hello World</div>")
  
  describe "an include tag with a composed dynamic template name", ->
    beforeEach ->
      @template = '<pop:content><div><pop:include template="templates/<pop:template />" /></div></pop:content>'
      @read = (name) -> if name == 'templates/hello-world' then "Hello <pop:content.title />" else null
      @content = {content: {title: 'World', template: 'hello-world'}}
    
    it "should include the right template", ->
      expect(new pop.Template({template: @template, read: @read})
      .render(this.content).trim())
      .toEqual("<div>Hello World</div>")

  describe "when compiling a template", ->
    describe "with a missing closing tag", ->
      beforeEach -> @template = "Something\n<pop:opentag>\nAnd something more"

      it "should raise an informative exception", ->
        test = this
        expect(-> new pop.Template({template: test.template}).compile()).toThrow(pop.TemplateError)

    describe "with a malformed tag", ->
      beforeEach -> @template = 'Something <pop:badtag and someinth more'

      it "should raise an informative exception", ->
        test = this
        expect(-> new pop.Template({template: test.template}).compile()).toThrow(pop.TemplateError)

    describe "with an error in a layout", ->
      beforeEach ->
        layout = '<html><pop:bad_tag <pop:region name="main" /></html>'
        @template = '<pop:layout name="default" /><pop:block region="main"><h1><pop:title /></h1></pop:block>'
        @content  = {title: "Hello, World!"}

        @read = (name) -> if name == 'layouts/default' then layout else null

      it "should replace the regions defined in the layout with the blocks defined in the template", ->
        test = this
        expect(->new pop.Template({template: test.template, read: test.read}).compile())
        .toThrow(pop.TemplateError)

  describe "filters", ->
    describe "an uppercase filter", ->
      beforeEach ->
        @template = '<pop:title format="uppercase" />'
        @content  = {title: 'Hello, World!'}
        @filters  =
          format: (value, options) ->  if options.format == 'uppercase' then value.toUpperCase()

      it "should transform the value to uppercase", ->
        expect(new pop.Template({template: @template, filters: @filters})
        .render(@content))
        .toEqual("HELLO, WORLD!")

  describe "shortcuts", ->
    describe "nesting with . for self closing tag", ->
      beforeEach ->
        @template = "<pop:content.title />"
        @content = {content: {title: "Hello"}}

      it "should repeat the enclosed tag and perform the substitution for each element", ->
        expect(new pop.Template({template: @template})
        .render(@content))
        .toEqual("Hello")

    describe "nesting with . for non self closing tag", ->
      beforeEach ->
        @template = "<pop:content.features><strong><pop:price /></strong></pop:content.features>"
        @content = {content: {features: {price: "$100"}}}

      it "should repeat the enclosed tag and perform the substitution for each element", ->
        expect(new pop.Template({template: @template})
        .render(@content))
        .toEqual("<strong>$100</strong>")

    describe "several levels of nesting with . for self closing tag", ->
      beforeEach ->
        @template = "<pop:content.author.name />"
        @content = {content: {author: {name: "Mathias"}}}

      it "should repeat the enclosed tag and perform the substitution for each element", ->
        expect(new pop.Template({template: @template})
        .render(@content))
        .toEqual("Mathias")

  describe "html entities", ->
    describe "when a string includes html entities", ->
      beforeEach ->
        @template = "<pop:text />"
        @content = {text: 'A "text" with & and <something>'}

      it "should escape them", ->
        expect(new pop.Template({template: @template})
        .render(@content))
        .toEqual("A &quot;text&quot; with &amp; and &lt;something&gt;")

      it "should not escape them if the escaping is disabled", ->
        @template = "<pop:text escape='false' />"
        expect(new pop.Template({template: @template})
        .render(@content))
        .toEqual("A \"text\" with & and <something>")

  describe "handle 0 different from null", ->
    beforeEach ->
      @template ="<pop:number />";
      @content = {number: 0};

    it "should show the 0", ->
      expect(new pop.Template({template: @template})
      .render(@content))
      .toEqual("0")

  describe "html comments", ->
    beforeEach ->
      @template ="<!-- <pop:number /> -->"
      @content = {number: 10}

    it "should not process html comments", ->
      expect(new pop.Template({template: @template})
      .render(@content))
      .toEqual("<!-- <pop:number /> -->")