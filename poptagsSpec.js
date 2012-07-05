pop  = require('poptags');

JSpec.describe("PopTags", function() {

  describe("When rendering a plain text with not tags", function() {
    it("should display the template", function(){
      var template = "I am a plain text";
      expect(new pop.Template({template: template}).render({})).to(be, "I am a plain text");
    });
  });

  describe("a tag", function() {
    before(function() {
      this.template = "<h1>Home - <pop:site_title /></h1>";
    });

    describe("with an empty scope", function() {
      before(function() {
        this.content  = {};
      });

      it("should render nothing", function() {
        expect(new pop.Template({template: this.template}).render(this.content)).
        to(be, "<h1>Home - </h1>");
      });
    });

    describe("with the variable in the scope", function() {
      before(function() {
        this.content = {site_title: "Webpop"};
      });

      it("should replace the tag with the value of the variable", function() {
        expect(new pop.Template({template: this.template}).render({site_title: "Webpop"})).
        to(be, "<h1>Home - Webpop</h1>");
      });
    });
  });

  describe("a tag with a nested tag", function() {
    before(function() {
      this.template = "<pop:content><li><pop:title /></li></pop:content>";
    });

    describe("with an array in the scope and variable inside", function() {
      before(function() {
        this.content = {content: [{title: "Hello"},{title: "World"}]};
      });

      it("should repeat the enclosed tag and perform the substitution for each element", function() {
        expect(new pop.Template({template: this.template}).render(this.content)).
        to(be, "<li>Hello</li><li>World</li>");
      });
    });

    describe("with a function returning an array", function() {
      before(function() {
        this.content = {
          content: function() {
            return [{title: "Hello"},{title: "World"}];
          }
        };
      });

      it("should repeat the enclosed tags and perform the substitution for each element", function() {
        expect(new pop.Template({template: this.template}).render(this.content)).
        to(be, "<li>Hello</li><li>World</li>");
      });
      
      it("should handle first and last", function() {
        expect(new pop.Template({template: "<pop:content break='li'><pop:first>First</pop:first><pop:last>Last</pop:last> <pop:title/></pop:content>"}).render(this.content)).
        to(be, "<li>First Hello</li><li>Last World</li>");
      });
      
      it("should handle first and last when the array elements are functions", function() {
        this.content = {content: function(){ return [{title: "Hello"}, {title: "World"}]}};
        expect(new pop.Template({template: "<pop:content break='li'><pop:first>First</pop:first><pop:last>Last</pop:last> <pop:title/></pop:content>"}).render(this.content)).
        to(be, "<li>First Hello</li><li>Last World</li>");
      });      

    });
  });

  describe("with an array of strings", function() {
    before(function() {
      this.content = {
        titles: ["Hello", "World"]
      };
    });

    describe("when rendered with no enclosed tags", function() {
      before(function() {
        this.template = '<pop:titles break=", "/>';
      });

      it("should render the strings", function() {
        expect(new pop.Template({template: this.template}).render(this.content)).
        to(be, "Hello, World");
      });

      it("should handle just one string", function() {
          expect(new pop.Template({template: this.template}).render({titles: ["Hello"]})).
          to(be, "Hello");
      });
      
      it("should handle first and last", function() {
         expect(new pop.Template({template: '<pop:titles break=", "><pop:first>First</pop:first><pop:last>Last</pop:last> <pop:value/></pop:titles>'}).render(this.content)).
         to(be, "First Hello, Last World");
      });
      
      it("should not have first and last outside the collection", function() {
         expect(new pop.Template({template: '<pop:titles break=", "/><pop:first>First</pop:first><pop:last>Last</pop:last>'}).render(this.content)).
         to(be, "Hello, World");
      });
    });
    
    describe("when rendering nested array and pop:first tags", function() {
      before(function() {
        this.template = '<pop:outer><pop:inner><pop:title/></pop:inner>, <pop:first><pop:title/></pop:first></pop:outer>';
        this.nested = {
          outer: [{
            title: "World",
            inner: [{title: "Hello"}]
          }]
        };
      });
      
      it("should render the strings", function() {
        expect(new pop.Template({template: this.template}).render(this.nested)).
        to(be, "Hello, World");
      });
      
    });
    

    describe("when rendered with enclosed tags", function() {
      before(function() {
        this.template = '<pop:titles><h2><pop:value /></h2></pop:titles>';
      });

      it("should render the enclosed tags for each string with the string available as value in the scope", function() {
        expect(new pop.Template({template: this.template}).render(this.content)).
        to(be, "<h2>Hello</h2><h2>World</h2>");
      });
    });

    describe("when rendered with the repeat=false option", function() {
      before(function() {
        this.template = '<pop:titles repeat="false"><h2><pop:values break=", " /></h2></pop:titles>';
      });

      it("should only render the enclosed tags once and pass the array to the values variable", function() {
        expect(new pop.Template({template: this.template}).render(this.content)).
        to(be, "<h2>Hello, World</h2>");
      });
      
      it("should still respect the no_ tag", function() {
        var content = {titles: []};
        var template = "<pop:titles repeat='false'>Something</pop:titles><pop:no_titles>Hello, World</pop:no_titles>";
        expect(new pop.Template({template: template}).render(content)).
        to(be, "Hello, World");
      });
    });

    describe("when using no repeat and skip", function() {
      before(function() {
        this.template = '<pop:titles repeat="false"><pop:values skip="1"><h2><pop:value /></h2></pop:values></pop:titles>';
      });

      it("should only render the enclosed tags once and pass the array to the values variable", function() {
        expect(new pop.Template({template: this.template}).render(this.content)).
        to(be, "<h2>World</h2>");
      });
    });

    describe("when using no repeat and limit", function() {
      before(function() {
        this.template = '<pop:titles repeat="false"><pop:values limit="1"><h2><pop:value /></h2></pop:values></pop:titles>';
      });

      it("should only render the enclosed tags once and pass the array to the values variable", function() {
        expect(new pop.Template({template: this.template}).render(this.content)).
        to(be, "<h2>Hello</h2>");
      });
    });

    describe("when using no repeat and skip and limit", function () {
      before(function() {
        this.template = '<pop:titles repeat="false"><pop:values skip="1" limit="1"><h2><pop:value /></h2></pop:values></pop:titles>';
      });

      it("should only render the enclosed tags once and pass the array to the values variable", function() {
        expect(new pop.Template({template: this.template}).render(this.content)).
        to(be, "<h2>World</h2>");
      });
    });
  });

  describe("with a function returning an array of more complex objects", function() {
    before(function() {
      this.template = '<pop:entries wrap="ul" break="li"><pop:content><h4><pop:title /></h4></pop:content></pop:entries>';
      this.content = {
        entries: function() {
          return [
            {"content":{"title":"Raspberry Stripe"}},
            {"content":{"title":"Denim Blue"}},
            {"content":{"title":"Cotton Candy"}}
          ];
        }
      };
    });

    it("should render the enclosed tags for each object", function() {
      expect(new pop.Template({template: this.template}).render(this.content)).
      to(be, "<ul><li><h4>Raspberry Stripe</h4></li><li><h4>Denim Blue</h4></li><li><h4>Cotton Candy</h4></li></ul>");
    });
  });

  describe("When rendering a template refering to content from an extension", function() {
    before(function() {
      this.template = "<title><pop:sample_extension:title /></title>";
      var sample_extension = {
        title: "Hello From Sample Extension"
      };
      this.require = function(name) {
        if(name == 'sample_extension') {
          return sample_extension;
        }
      };
    });

    it("should require the extension and get the content from there", function() {
      expect(new pop.Template({template: this.template, require: this.require}).render({})).
      to(be, "<title>Hello From Sample Extension</title>");
    });

    describe("with a no tag", function() {
      before(function() {
        this.template = "<title><pop:ext:title>Hello</pop:ext:title><pop:ext:no_title>No title</pop:ext:no_title></title>";
        this.require = function(name) {
          if(name == 'ext') {
            return {title: null};
          }
        };
      });

      it("shuld render the no tag when", function() {
        expect(new pop.Template({template: this.template, require: this.require}).render({})).
        to(be, "<title>No title</title>");
      });
    });
  });

  describe("When rendering tags within a tag that changes the scope to that of an extension", function() {
    before(function() {
      this.template = "<title><pop:ext:post><pop:title /></pop:ext:post></title>";
      var ext = {
        post: function() {
          return {
            title: 'Hello'
          };
        }
      };
      this.require = function(name) {
        if(name == 'ext') {
          return ext;
        }
      };
    });

    it("should use the content from the extension", function() {
      expect(new pop.Template({template: this.template, require: this.require}).render({})).
      to(be, "<title>Hello</title>");
    });
  });

  describe("When rendering a template that passes options to a tag", function() {
    before(function() {
      this.content = {
        posts: function(options) {
          var a = [];
          for(var i=0; i<options.limit; i++) {
            a.push({id: i+1});
          }
          return a;
        }
      };
    });

    describe("when double-quoting the option", function() {
      before(function() {
        this.template = "<pop:posts limit=\"3\"><li><pop:id /></li></pop:posts>";
      });

      it("should pass the options to the tag", function() {
        expect(new pop.Template({template: this.template}).render(this.content)).
        to(be, "<li>1</li><li>2</li><li>3</li>");
      });
    });

    describe("when single-quoting the option", function() {
      before(function() {
        this.template = "<pop:posts limit='3'><li><pop:id /></li></pop:posts>";
      });

      it("should pass the options to the tag", function() {
        expect(new pop.Template({template: this.template}).render(this.content)).
        to(be, "<li>1</li><li>2</li><li>3</li>");
      });
    });
    
    describe("when passing an extension method as the option", function() {
      before(function() {
        var sample_extension = {
          limit: function() { return 3; }
        };
        this.require = function(name) {
          if(name == 'sample_extension') {
            return sample_extension;
          }
        };
        this.template = "<pop:posts limit='<pop:sample_extension:limit/>'><li><pop:id /></li></pop:posts>";
      });
      
      it("should call the function and pass the result to the tag", function() {
        expect(new pop.Template({template: this.template, require: this.require}).render(this.content)).
        to(be, "<li>1</li><li>2</li><li>3</li>");
      });
    });
    
    describe("when passing an extension method as the option to a tag with a html function", function() {
      before(function() {
        var sample_extension = {
          name: function() { return "World!"; }
        };
        this.require = function(name) {
          if(name == 'sample_extension') {
            return sample_extension;
          }
        };
        this.content = {
          greet: {
            html: function(options) {
              return "Hello, " + options.name;
            }
          }
        };
        this.template = "<pop:greet name='<pop:sample_extension:name/>'/>";
      });
      
      it("should call the function and pass the result to the tag", function() {
        expect(new pop.Template({template: this.template, require: this.require}).render(this.content)).
        to(be, "Hello, World!");
      });
    });    
  });

  describe("When rendering a template with default content", function() {
    before(function() {
      this.template = "<pop:something><pop:title default=\"Hello\" /></pop:something>" +
                      "<pop:no_something>No Content</pop:no_something>";
    });

    describe("with no content", function() {
      before(function() {
        this.content = {};
      });

      it("should render the no_content tag", function() {
        expect(new pop.Template({template: this.template}).render(this.content).trim()).
        to(be, "No Content");
      });
    });


    describe("with content but no value for the tag", function() {
      before(function() {
        this.content = {something: {}};
      });

      it("should render the value of the 'default' attribute", function() {
        expect(new pop.Template({template: this.template}).render(this.content).trim()).
        to(be, "Hello");
      });
    });

    describe("when the tempate has a pop tag in the default attribute", function() {
      before(function() {
        this.tempate = "<pop:something default='<pop:something_else />'/>";
        this.content = {
          something_else: "Hello"
        };
      });

      it("should render the result of evaluating the pop tag", function() {
        expect(new pop.Template({template: this.tempate}).render(this.content).trim()).
        to(be, "Hello");
      });
    });

    describe("when the layout is chosen by an pop tag", function() {
      before(function() {
        this.layout = "<h1><pop:region name='main'/></h1>";
        this.template = "<pop:layout name='<pop:the_layout/>'/><pop:block region='main'>Hello</pop:block>";
        this.content = {
          the_layout: "layout"
        };
        var self = this;
        this.read = function(name) {
          if (name == 'layouts/layout') return self.layout;
        };
      });

      it("should render the right layout", function() {
        expect(new pop.Template({template: this.template, read: this.read}).render(this.content).trim()).
        to(be, "<h1>Hello</h1>");
      });
    });

    describe("with a no_ tag and an include inside", function() {
      before(function() {
        var self = this;
        this.template = "<pop:layout name='outer' /><pop:block region='main'><pop:content><pop:test>Test: <pop:include template='inner' /></pop:test><pop:no_test><pop:include template='inner' /></pop:no_test></pop:content></pop:block>";
        this.outer   = "<pop:region name='main' />";
        this.inner   = "<h1><pop:title /></h1>";
        this.content = {content: {title: "Hello", test: []}};
        this.read = function(name) {
          if (name == 'inner') return self.inner;
          if (name == 'layouts/outer') return self.outer;
        };
      });

      it("should render the result of evaluating the pop tag", function() {
        expect(new pop.Template({template: this.template, read: this.read}).render(this.content).trim()).
        to(be, "<h1>Hello</h1>");
      });

    });
  });

  describe("no content tag inside a collection", function() {
    before(function() {
      this.template = "<pop:something><pop:title /><pop:no_title>No Title </pop:no_title></pop:something>";
    });

    describe("where some has the content and some doesn't", function() {
      before(function() {
        this.content = {something: [
          {},
          {title: "Yes Title"}
        ]};
      });

      it("should render the no_content tag", function() {
        expect(new pop.Template({template: this.template}).render(this.content).trim()).
        to(be, "No Title Yes Title");
      });
    });
  });
  
  describe("using lookup on the scope in a tag", function() {
    before(function() {
      this.template = "<pop:content><pop:something><pop:t name='title'/></pop:something></pop:content>";
      this.content = {
        content: {title: "Hello, World"},
        something: {testing: "Testing"},
        t: function(options, enclosed, scope) {
          return scope.lookup(options.name);
        }
      }
    });
    
    it("should crawl up the scope chain", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "Hello, World");
      
    });
  });

  describe("When rendering a template with a filter", function() {
    before(function() {
      this.template = "<pop:upcase>hello world</pop:upcase>";
      this.content = {
        upcase: function(options, enclosing) {
          return enclosing.render().toUpperCase();
        }
      };
    });

    it("should call the filter with the enclosed text", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "HELLO WORLD");
    });
  });

  describe("When rendering a template with a filtered text and substitution", function() {
    before(function() {
      this.template = "<pop:upcase><pop:title /></pop:upcase>";
      this.content = {
        upcase: function(options, enclosing) {
          return enclosing.render().toUpperCase();
        },
        title: "Hello world"
      };
    });

    it("should let the filter render the enclosed tags and replace them with the result", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "HELLO WORLD");
    });
  });

  describe("a tag with a wrap attribute", function() {
    before(function() {
      this.template = '<pop:title wrap="span" />';
      this.content = {title: 'I should be wrapped in a span'};
    });

    it("should wrap the content in the element specified in the attribute", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "<span>I should be wrapped in a span</span>");
    });
  });

  describe("a tag with with a wrap and a class attribute", function() {
    before(function() {
      this.template = '<pop:title wrap="span" class="title"/>';
      this.content = {title: 'I should be wrapped in a span'};
    });

    it("should add the class to the wrap element", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "<span class=\"title\">I should be wrapped in a span</span>");
    });
  });

  describe("a tag with a wrap attribute for an empty element", function() {
    before(function() {
      this.template = '<pop:title wrap="span" class="title"/>';
      this.content = {};
    });

    it("should not add the wrap element", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "");
    });
    
    it("should not add the wrap element when the value is an empty array", function() {
      this.content.title = [];
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "");
    });

    it("should work with repeat false", function() {
      this.content.title = [];
      var template = '<pop:title wrap="span" class="title" repeat="false" />'
      expect(new pop.Template({template: template}).render(this.content).trim()).
      to(be, "");
    });
    
    it("should work with a function returning an empty array", function() {
      this.content.title = function() { return []; };
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "");
    });
  });

  describe("a tag with wrap and break attributes", function() {
    before(function() {
      this.template = '<pop:posts wrap="ul" break="li"><pop:title /></pop:posts>';
      this.content = {posts: [{title:'post 1'}, {title: 'post 2'}]};
    });

    it("should wrap the content in the wrap element and wrap each repetition in the break element", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "<ul><li>post 1</li><li>post 2</li></ul>");
    });
  });

  describe("a tag with a break attribute that is not an html tag", function() {
    before(function() {
      this.template = '<pop:posts break=", "><pop:title /></pop:posts>';
      this.content = {posts: [{title:'post 1'}, {title: 'post 2'}, {title: 'post 3'}]};
    });

    it("should separate each repetition with the value of the break attribute", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "post 1, post 2, post 3");
    });

    describe("and a last attribute", function() {
      before(function() {
        this.template = '<pop:posts break=", " last=" and "><pop:title /></pop:posts>';
      });

      it("should separate each repetition with the value of the break attribute and the last 2 with the value of the last attribute", function() {
        expect(new pop.Template({template: this.template}).render(this.content).trim()).
        to(be, "post 1, post 2 and post 3");
      });
    });
  });

  describe("a tag with a break attribute that is an html5 self-closing tag", function() {
    before(function() {
      this.template = '<pop:posts break="br"><pop:title /></pop:posts>';
      this.content = {posts: [{title:'post 1'}, {title: 'post 2'}]};
    });

    it("should separate each repetition with the value of the break attribute", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "post 1<br />post 2");
    });
  });

  describe("a self-closing tag for a boolean element that is true", function() {
    before(function() {
      this.template = '<pop:readmore />';
      this.content = {readmore: true};
    });

    it("should render the string 'true'", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "true");
    });
  });

  describe("a self-closing tag for a boolean element that is false", function() {
    before(function() {
      this.template = '<pop:readmore />';
      this.content = {readmore: false};
    });

    it("should render the string 'false'", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "false");
    });
  });

  describe("a tag for a boolean element that is true and has enclosed content", function() {
    before(function() {
      this.template = '<pop:readmore>You can read more</pop:readmore>';
      this.content = {readmore: true};
    });

    it("should render the enclosed content", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "You can read more");
    });
  });

  describe("a tag for a boolean element that is false and has enclosed content", function() {
    before(function() {
      this.template = '<pop:readmore>You can read more</pop:readmore>';
      this.content = {readmore: false};
    });

    it("should render nothing", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "");
    });
  });

  describe("a tag for a boolean element that is false and has default content", function() {
    before(function() {
      this.template = '<pop:readmore default="You cannot read more">You can read more</pop:readmore>';
      this.content = {readmore: false};
    });

    it("should render nothing", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "You cannot read more");
    });
  });

  describe("a tag for a string element that is enclosing other tags", function() {
    before(function() {
      this.template = '<pop:title>Title: <pop:title /></pop:title>';
      this.content = {title: 'Hello, World!'};
    });

    it("should render the enclosed content", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "Title: Hello, World!");
    });
  });

  describe("a tag for a non-existing element that is enclosing other tags", function() {
    before(function() {
      this.template = '<pop:title>Title: <pop:title /></pop:title>';
      this.content = {};
    });

    it("should render nothing", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "");
    });
  });

  describe("a tag for an undefined element", function() {
    before(function() {
      this.template = '<pop:title />';
      var title;
      this.content = {title: title};
    });

    it("should render nothing", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "");
    });
  });

  describe("a tag with an undefined html value and a bad toString method", function() {
    before(function() {
      this.template = '<pop:title />';
      var title;
      this.content = {title: {html: title, toString: function() { return title; }}};
    });

    it("should render nothing", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "");
    });
  });

  describe("a tag with an empty html value", function() {
    before(function() {
      this.template = '<pop:title />';
      this.content = {title: {html: null}};
    });

    it("should render nothing", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "");
    });
  });

  describe("a tag for an undefined element that is exists further up in the scope", function() {
    before(function() {
      this.template = '<pop:content>Title: <pop:title /></pop:content>';
      var Content = function() {};
      Content.prototype.title = function() { };
      this.content = {title: "Hello, World", content: new Content};
    });

    it("should render nothing", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "Title:");
    });

  });

  describe("a tag for an non existing element that is exists further up in the scoe", function() {
    before(function() {
      this.template = '<pop:content>Title: <pop:title /></pop:content>';
      var Content = function() {};
      this.content = {title: "Hello, World", content: new Content};
    });

    it("should render nothing", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "Title: Hello, World");
    });

  });

  describe("a self-closing tag for an object with an html function", function() {
    before(function() {
      this.template = 'Read more: <pop:link text="here" />';
      this.content = {
        link: {
          html: function(options) {
            return "<a href='/slug'>"+options.text+"</a>";
          }
        }
      };
    });

    it("should render the result of calling the html function", function() {
      expect(new pop.Template({template: this.template}).render(this.content).trim()).
      to(be, "Read more: <a href='/slug'>here</a>");
    });
  });

  describe("an include tag", function() {
    before(function() {
      this.template = '<div><pop:include template="hello-world" /></div>';
      this.read = function(name) {
        return name == 'hello-world' ? "Hello <pop:title />" : null;
      };
      this.content = {title: 'World'};
    });

    it("should include another template into the current one", function() {
      expect(new pop.Template({template: this.template, read: this.read}).render(this.content).trim()).
      to(be, "<div>Hello World</div>");
    });
  });

  describe("a template that includes itself", function() {
    before(function() {
      var template = '<ul><pop:files><pop:dir><pop:include template="listing" /></pop:dir><pop:file><li><pop:name/></li></pop:file></pop:files></ul>';
      this.read = function(name) {
        return name == 'listing' ? template : null;
      };
      this.content = {
        files: [
          {file: true, name: "test.txt", dir: false},
          {dir: true, files: [
            {file: true, dir: false, name: "/a/test.txt"}
          ]}
        ]
      };
    });

    it("should not go into an endless loop :P", function() {
      expect(new pop.Template({name: 'listing', read: this.read}).render(this.content).trim()).
      to(be, "<ul><li>test.txt</li><ul><li>/a/test.txt</li></ul></ul>");
    });
  });

  describe("a template that includes itself and recurses several times", function() {
    before(function() {
      var template = '<ul><pop:files><pop:dir><pop:include template="listing" /></pop:dir><pop:file><li><pop:name/> - <pop:global /></li></pop:file></pop:files></ul>';
      this.read = function(name) {
        return name == 'listing' ? template : null;
      };
      this.content = {
        global: function() { return "I am global!"; },
        files: [
            {file: true, name: "test.txt", dir: false},
            {dir: true, files: [
              {file: true, dir: false, name: "/a/test.txt"},
              {dir: true, file: false, files: [
                {file: true, dir: false, name: "/a/b/test.txt"}
              ]}
            ]}
          ]
      };
    });

    it("should have access to the global scope", function() {
      expect(new pop.Template({name: 'listing', read: this.read}).render(this.content).trim()).
      to(be, "<ul><li>test.txt - I am global!</li><ul><li>/a/test.txt - I am global!</li><ul><li>/a/b/test.txt - I am global!</li></ul></ul></ul>");
    });
  });

  describe("a template with a layout", function() {
    before(function() {
      var layout   = '<html><pop:region name="main" /></html>';
      this.template = '<pop:layout name="default" /><pop:block region="main"><h1><pop:title /></h1></pop:block>';
      this.content  = {title: "Hello, World!"};

      this.read = function(name) {
        return name == 'layouts/default' ? layout : null;
      };
    });

    it("should replace the regions defined in the layout with the blocks defined in the template", function() {
      expect(new pop.Template({template: this.template, read: this.read}).render(this.content).trim()).
      to(be, "<html><h1>Hello, World!</h1></html>");
    });
  });

  describe("a template with layout and no block for a region", function() {
    before(function() {
      var layout   = '<html><pop:region name="main">Default content for main</pop:region></html>';
      this.template = '<pop:layout name="default" />';

      this.read = function(name) {
        return name == 'layouts/default' ? layout : null;
      };
    });

    it("should render the contents of the region defined in the layout", function() {
      expect(new pop.Template({template: this.template, read: this.read}).render({}).trim()).
      to(be, "<html>Default content for main</html>");
    });
  });

  describe("a tag with a dynamic attribute", function() {
    before(function() {
      this.template = '<pop:output value="Hello, <pop:something />" />';
      this.content = {
        output: function(options) {
          return options.value;
        },
        something: 'World!'
      };
    });

    it("should get the attribute with the proper value", function() {
      expect(new pop.Template({template: this.template}).render(this.content)).
      to(be, "Hello, World!");
    });
  });

  describe("an include tag with a dynamic template name", function() {
    before(function() {
      this.template = '<div><pop:include template="<pop:template />" /></div>';
      this.read = function(name) {
        return name == 'hello-world' ? "Hello <pop:title />" : null;
      };
      this.content = {title: 'World', template: 'hello-world'};
    });

    it("should include the right template", function() {
      expect(new pop.Template({template: this.template, read: this.read}).render(this.content).trim()).
      to(be, "<div>Hello World</div>");
    });
  });
  
  describe("an include tag with a composed dynamic template name", function() {
    before(function() {
      this.template = '<pop:content><div><pop:include template="templates/<pop:template />" /></div></pop:content>';
      this.read = function(name) {
        return name == 'templates/hello-world' ? "Hello <pop:content.title />" : null;
      };
      this.content = {content: {title: 'World', template: 'hello-world'}};
    });
    
    it("should include the right template", function() {
      expect(new pop.Template({template: this.template, read: this.read}).render(this.content).trim()).
      to(be, "<div>Hello World</div>");
    });
  });

  describe("when compiling a template", function() {
    describe("with a missing closing tag", function() {
      before(function() {
        this.template = "Something\n<pop:opentag>\nAnd something more";
      });

      it("should raise an informative exception", function() {
        var test = this;
        expect(function() {new pop.Template({template: test.template}).compile();}).to(throw_error, pop.TemplateError);
      });
    });

    describe("with a malformed tag", function() {
      before(function() {
        this.template = 'Something <pop:badtag and someinth more';
      });

      it("should raise an informative exception", function() {
        var test = this;
        expect(function() {new pop.Template({template: test.template}).compile();}).to(throw_error, pop.TemplateError);
      });
    });

    describe("with an error in a layout", function() {
      before(function() {
        var layout   = '<html><pop:bad_tag <pop:region name="main" /></html>';
        this.template = '<pop:layout name="default" /><pop:block region="main"><h1><pop:title /></h1></pop:block>';
        this.content  = {title: "Hello, World!"};

        this.read = function(name) {
          return name == 'layouts/default' ? layout : null;
        };
      });

      it("should replace the regions defined in the layout with the blocks defined in the template", function() {
        var test = this;
        expect(function() {
          new pop.Template({template: test.template, read: test.read}).compile();
        }).to(throw_error, pop.TemplateError);
      });
    });
  });

  describe("filters", function() {
    describe("an uppercase filter", function() {
      before(function() {
        this.template = '<pop:title format="uppercase" />';
        this.content  = {title: 'Hello, World!'};
        this.filters  = {
          format: function(value, options) {
            if(options.format == 'uppercase') {
              return value.toUpperCase();
            }
          }
        };
      });

      it("should transform the value to uppercase", function() {
        expect(new pop.Template({template: this.template, filters: this.filters}).render(this.content)).
        to(be, "HELLO, WORLD!");
      });
    });

    // describe("A filter from an extension", function() {
    //   before(function() {
    //     this.template = '<pop:title text:format="uppercase" />';
    //     this.content  = {title: 'Hello, World!'};
    //     this.require = function(name) {
    //       if (name == "text") {
    //         return {text: function(value, options) {
    //           if (options.format == "uppercase") {
    //             return value.toUpperCase();
    //           }
    //         }};
    //       }
    //     };
    //   });
    //
    //   it("should transform the value to uppercase", function() {
    //     expect(new pop.Template({template: this.template, filters: this.filters}).render(this.content)).
    //     to(be, "HELLO, WORLD!");
    //   });
    // });

  });

  describe("shortcuts", function() {
    describe("nesting with . for self closing tag", function() {
      before(function() {
        this.template = "<pop:content.title />";
        this.content = {content: {title: "Hello"}};
      });

      it("should repeat the enclosed tag and perform the substitution for each element", function() {
        expect(new pop.Template({template: this.template}).render(this.content)).
        to(be, "Hello");
      });
    });

    describe("nesting with . for non self closing tag", function() {
      before(function() {
        this.template = "<pop:content.features><strong><pop:price /></strong></pop:content.features>";
        this.content = {content: {features: {price: "$100"}}};
      });

      it("should repeat the enclosed tag and perform the substitution for each element", function() {
        expect(new pop.Template({template: this.template}).render(this.content)).
        to(be, "<strong>$100</strong>");
      });
    });

    describe("several levels of nesting with . for self closing tag", function() {
      before(function() {
        this.template = "<pop:content.author.name />";
        this.content = {content: {author: {name: "Mathias"}}};
      });

      it("should repeat the enclosed tag and perform the substitution for each element", function() {
        expect(new pop.Template({template: this.template}).render(this.content)).
        to(be, "Mathias");
      });
    });
  });

  describe("html entities", function() {
    describe("when a string includes html entities", function() {
      before(function() {
        this.template = "<pop:text />";
        this.content = {text: 'A "text" with & and <something>'};
      });

      it("should escape them", function() {
        expect(new pop.Template({template: this.template}).render(this.content)).
        to(be, "A &quot;text&quot; with &amp; and &lt;something&gt;");
      });

      it("should not escape them if the escaping is disabled", function() {
        this.template = "<pop:text escape='false' />";
        expect(new pop.Template({template: this.template}).render(this.content)).
        to(be, "A \"text\" with & and <something>");
      });
    });
  });

  describe("handle 0 different from null", function() {
    before(function() {
      this.template ="<pop:number />";
      this.content = {number: 0};
    });

    it("should show the 0", function() {
      expect(new pop.Template({template: this.template}).render(this.content)).
      to(be, "0");
    });
  });

  describe("html comments", function() {
    before(function() {
      this.template ="<!-- <pop:number /> -->";
      this.content = {number: 10};
    });

    it("should not process html comments", function() {
      expect(new pop.Template({template: this.template}).render(this.content)).
      to(be, "<!-- <pop:number /> -->");
    });
  });
});