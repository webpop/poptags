PopTags Template Engine
-----------------------

PopTags is a declarative template engine written in CoffeeScript and used for rendering Webpop sites.

PopTags doesn't keeps code and pure templates strictly separated, while giving plenty of declarative power to templates.

Usage
=====

    var template = new PopTags.Template({template: "<pop:title wrap='h1'/>"})
    var html = template.render({title: "Hello, World!"}); // -> <h1>Hello, World!</h1>

Reading Includes and Layouts
============================

The *read* function are used for looking up templates when using `<pop:include>` or `<pop:layout>`:

    var templates = {
      main: "<pop:include template='partial'/>",
      partial: "<pop:title wrap='h1'/>"
    };

    var read = function(name) {
      return templates[name];
    };
    
    var template = new PopTags.Template({read: read, name: "main"});
    var html = template.render({title: "Hello, World!"}); // -> <h1>Hello, World!</h1>

Adding Filters
==============

PopTags allow you to define filters that can be applied via attributes.

    var filters = {
      format: function(value, options) {
        switch(options.format) {
          case "upcase":
            return value.toUpperCase();
          case "downcase":
            return value.toLowerCase();
        }
        return value;
      }
    };
    
    var template = new PopTags.Template({template: "<pop:title format='upcase' wrap='h1' />", filters: filters});
    var html = template.render({title: "Hello, World!"}); // -> <h1>HELLO, WORLD!</h1>

Pulling in CommonJS modules
===========================

The *require* function are used for dynamically pulling in CommonJS and use their exported methods as tags:

    var modules = {
      hello: {
        world: function(options, enclosed, tags) { return "Hello, World!"; }
      }
    };

    var require = function(name) {
      return modules[name];
    };
    
    var template = new PopTags.Template({template: "<pop:hello:world wrap='h1'/>", require: require});
    var html = template.render(); // -> <h1>Hello, World!</h1>