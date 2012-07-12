exports ?= {}

CONSTANTS =
  LAYOUT_TAG:       'layout'
  INCLUDE_TAG:      'include'
  REGION_TAG:       'region'
  BLOCK_TAG:        'block'
  START_TAG_RE:     /^<pop:(\w+[a-zA-Z0-9_:\.-]*)((?:\s+\w+(?:\s*=\s*(?:(?:"[^"]*")|(?:'[^']*')))?)*)\s*\/?>/
  END_TAG_RE:       /^<\/pop:(\w+[a-zA-Z0-9_:\.-]*)\s*>/
  SELF_CLOSING_RE:  /\/>$/m
  ATTRIBUTES_RE:    /(\w+)(?:\s*=\s*(?:(?:"((?:\\.|[^"])*)")|(?:'((?:\\.|[^'])*)')))/g
  START_TAG:        "<pop:"
  END_TAG:          "</pop:"
  COMMENT_TAG:      "<!--"
  COMMENT_TAG_END:  "-->"
  CONTAINS_TAGS_RE: /<pop:/

  SELF_CLOSING:
    br: true
    hr: true

escapeHtml = (html) ->
  new String(html)
    .replace(/&/gmi, '&amp;')
    .replace(/'/gmi, '&#x27;')
    .replace(/"/gmi, '&quot;')
    .replace(/>/gmi, '&gt;')
    .replace(/</gmi, '&lt;')

wrap = (text, tag, klass) ->
  return text unless tag && text

  result = "<#{tag}"
  result += " class=\"#{klass}\"" if klass
  return "#{result}>#{text}</#{tag}>"

breakFn = (c, separator, last) ->
  return separateFn(c, separator, last) unless (/^[a-zA-Z]+$/).test(separator)
  return separateFn(c, '<' + separator + ' />') if CONSTANTS.SELF_CLOSING[separator]
  delimitFn('<' + separator + '>', '</' + separator + '>')

separateFn = (c, separator, last) ->
  end = c.length - 1

  (value, index) ->
    separator = last || separator if index == end
    if index == 0 then value else separator + value

delimitFn = (open, close) ->
  open  ||= ''
  close ||= ''

  (value) -> open + value + close

class TemplateError extends Error
  constructor: (message, location, filename) ->
    @name     = "TemplateError"
    @message  = message
    @location = location
    @filename = filename

class Ast
  constructor: (@require, @filters, @value_wrapper) ->
    @root        = new EnclosingTag
    @current_tag = @root
    @layout      = null
    @includes    = {}

  start_document: (parser) ->

  end_document: (parser) ->
    if @current_tag == @root
      @_handle_layout(parser, @layout) if @layout
    else if @current_tag.parent && !@current_tag.include_tag && !@current_tag.layout_tag
      @no_closing_tag(parser, @current_tag.name)

  start_tag: (parser, name, options) ->
    new_tag = new Tag(name, @current_tag, options, @require, this)
    new_tag.value_wrapper = @value_wrapper
    new_tag.position = parser.position

    if name == CONSTANTS.BLOCK_TAG
      @block_tag_without_layout(parser, name) unless @layout
      @layout.blocks[options.region] = new_tag
      @current_tag = new_tag
    else
      if name == CONSTANTS.LAYOUT_TAG
        @layout_already_defined(parser, name) if @layout
        @layout = new_tag
      if options and @filters
        for own key, _ of options
          new_tag.add_filter(@filters[key]) if @filters[key]
      @current_tag.push new_tag
      @current_tag = new_tag

  end_tag: (parser, name) ->
    while not @current_tag.is_closing(name)
      @current_tag = @current_tag.parent
      unless @current_tag && @current_tag.parent
        @unmatched_closing_tag(parser, name)

    if name == CONSTANTS.INCLUDE_TAG
      @_handle_include(parser, @current_tag)

    @current_tag = @current_tag.parent

  text: (parser, text) ->
    @current_tag.push text

  _handle_include: (parser, include_tag) ->
    template_name = include_tag.options.template
    template      = @includes[template_name]

    if template_name.render
      include_tag.read    = parser.read
      include_tag.require = @require
    else if template
      include_tag.enclosing = template.enclosing
    else
      @includes[template_name] = include_tag
      new Parser(parser.read).parse(parser.read(template_name), this, template_name)

  _handle_layout: (parser, layout) ->
    layout_name = layout.options.name

    if layout_name.render
      layout.read    = parser.read
      layout.require = @require
    else
      @current_tag = layout
      new Parser(parser.read).parse(parser.read("layouts/#{layout_name}"), this, "layouts/#{layout_name}")

  unmatched_closing_tag: (parser, name) ->
    throw(new TemplateError("closing tag </pop:#{name}> did not match any opening tag", parser.get_location(), parser.filename))

  no_closing_tag: (parser, name) ->
    throw(new TemplateError("no closing tag for <pop:#{name}>", parser.get_location(@current_tag.position), parser.filename))

  block_tag_without_layout: (parser, name) ->
    throw(new TemplateError("block tag without layout", parser.get_location(), parser.filename))

  layout_already_defined: (parser, name) ->
    throw(new TemplateError("layout already defined", parser.get_location(), parser.filename))

class Parser
  constructor: (read) ->
    @read = read

  next_tag_index: (next_start, next_end, next_comment) ->
    return -1 if next_start < 0 && next_end < 0 && next_comment < 0
    Math.min(
      if next_start   < 0 then Infinity else next_start,
      if next_end     < 0 then Infinity else next_end,
      if next_comment < 0 then Infinity else next_comment
    )

  get_line_number: (template, position) ->
    newlines = template.substring(0, position).match(/\n/g)
    if newlines then newlines.length + 1 else 1

  get_character: (template, line_number, position) ->
    template.split(/\n/)[0..line_number-1].join("").length

  get_location: (position) ->
    line_number = @get_line_number(@template, position || @position)
    {
      line: line_number
      character: @get_character(@template, line_number, position || @position)
    }

  parse: (template, handler, filename) ->
    parser = this
    template_chunk = template
    offset = 0

    @template = template
    @filename = filename
    @position = 0

    handler.start_document(this)
    while template_chunk
      tag_match = null

      if template_chunk.indexOf(CONSTANTS.COMMENT_TAG) == 0
        tag_match = true
        next_tag_index = template_chunk.indexOf(CONSTANTS.COMMENT_TAG_END)
        text = if next_tag_index < 0 then template_chunk else template_chunk.substring(0, next_tag_index)
        handler.text(this, text)
        offset = if next_tag_index < 0 then template_chunk.length else next_tag_index

      else if template_chunk.indexOf(CONSTANTS.START_TAG) == 0
        unless tag_match = template_chunk.match(CONSTANTS.START_TAG_RE)
          throw(new TemplateError("syntax error", @get_location(), @filename))

        tags           = null
        options        = {}
        tag_name       = tag_match[1]
        tag_attributes = tag_match[2]

        if tag_name.indexOf('.') != 1
          tags = tag_name.split('.')
          tag_name = tags.pop()
          handler.start_tag(this, tag, {})  for tag in tags

        if tag_attributes
          tag_attributes.replace CONSTANTS.ATTRIBUTES_RE, (match, name, doublequoted_value, singlequoted_value) ->
            if (value = doublequoted_value or singlequoted_value).match(CONSTANTS.CONTAINS_TAGS_RE)
              options[name] = new Template({template: value, filters: handler.filters, read: @read, require: handler.require}).compile()
              options[name].parent = handler.current_tag
            else
              options[name] = value

        handler.start_tag(this, tag_name, options)

        offset = tag_match[0].length
        if tag_match[0].match(CONSTANTS.SELF_CLOSING_RE)
          handler.end_tag(this, tag_name)
          if tags
            while tag = tags.pop()
              handler.end_tag(this, tag)

      else if template_chunk.indexOf(CONSTANTS.END_TAG) == 0
        tag_match = template_chunk.match(CONSTANTS.END_TAG_RE)
        throw(new TemplateError("syntax error", @get_location(), @filename)) unless tag_match

        tags = null
        tag_name = tag_match[1]
        if tag_name.indexOf('.') != -1
          tags = tag_name.split('.')
          tag_name = tags.pop()

        handler.end_tag(this, tag_name)
        if tags
          while tag = tags.pop()
            handler.end_tag(this, tag)

        offset = tag_match[0].length

      unless tag_match
        next_tag_index = @next_tag_index(
          template_chunk.indexOf(CONSTANTS.START_TAG),
          template_chunk.indexOf(CONSTANTS.END_TAG),
          template_chunk.indexOf(CONSTANTS.COMMENT_TAG)
        )
        text = if next_tag_index < 0 then template_chunk else template_chunk.substring(0, next_tag_index)
        handler.text(this, text)
        offset = if next_tag_index < 0 then template_chunk.length else next_tag_index
      throw(new TemplateError("syntax error", @get_location(), @filename)) if offset == 0
      @position += offset
      template_chunk = template_chunk.substring(offset)

    handler.end_document(this)

class Node

class EnclosingTag extends Node
  constructor: ->
    @collection = []
    @lastEmpty = null

  render: (scope) ->
    @scope = scope
    rendered_children = for child in @collection
      if child.render? then child.render(scope) else child.toString()
    rendered_children.join("")

  push: (obj) ->
    obj.index = @collection.length
    @collection.push obj

  is_empty: -> @collection.length == 0

  is_closing: -> false

class Tag extends Node
  constructor: (name, parent, options, require, ast) ->
    route  = name.split(':')
    @qualified_name = name
    @name           = route.pop()
    @module         = route.pop()

    no_tag = @name.match(/^not?_(.+)/)

    @module_scope   = {}
    @filters        = []
    @enclosing      = new EnclosingTag
    @blocks         = {}
    @parent         = parent
    @options        = options || {}
    @require        = require
    @ast            = ast
    @no_tag         = no_tag && if @module then "#{@module}:#{no_tag[1]}" else no_tag[1]
    @include_tag    = @qualified_name.toLowerCase() == CONSTANTS.INCLUDE_TAG
    @region_tag     = @qualified_name.toLowerCase() == CONSTANTS.REGION_TAG
    @block_tag      = @qualified_name.toLowerCase() == CONSTANTS.BLOCK_TAG
    @layout_tag     = @qualified_name.toLowerCase() == CONSTANTS.LAYOUT_TAG

  push: (obj) -> @enclosing.push obj

  is_closing: (name) -> name == @qualified_name

  has_children: -> @enclosing.collection.length > 0

  add_filter: (filter) -> @filters.push filter

  get_option: (name) ->
    opt = @options[name]
    if opt and opt.render then opt.render(@scope) else opt

  get_block: ->
    tag = this
    while not (tag.blocks && tag.blocks[@options.name]) && tag.parent
      tag = tag.parent

    tag.blocks && tag.blocks[@options.name]

  get_value: ->
    @module_scope = @require(@module) if @module

    tag = this
    while not (@name of @module_scope || @name of tag.scope) && (tag.parent && tag.parent.scope)
      tag = tag.parent

    @_tag_fn_scope = tag.scope
    if @value_wrapper
      @value_wrapper.wrap(@module_scope[@name] || tag.scope[@name], this)
    else
      @module_scope[@name] || tag.scope[@name]

  default_value: ->
    def = @get_option('default')
    return def if def

    @parent.last_empty = @qualified_name
    ""

  tags: (filter) ->
    tags = []
    if filter
      tag for tag in @enclosing.collection when tag.render and filter(tag)
    else
      tag for tag in @enclosing.collection
  
  # This method make sure that all keys in the option that are in reality
  # nested poptags templates get rendered.
  render_options: ->
    options = {}
    for key of @options
      options[key] = @get_option(key)

    options

  render_collection: (c) ->
    return "" unless c.length

    if @options.repeat == "false"
      return @enclosing.render
        length: c.length
        values: c.length && (options, enclosing) ->
          if options.skip or options.limit
            skip  = if options.skip  then parseInt(options.skip, 10) else 0
            limit = if options.limit then parseInt(options.limit, 10) else c.length
            c[skip...(skip+limit)]
          else
            c

    self   = this
    brk    = @get_option('break')
    fn     = brk && breakFn(c, brk, @get_option('last'))
    result = []
    index  = 0
    
    _first = self.scope.first
    _last  = self.scope.last

    c.forEach (el) ->
      self.scope.first = index == 0
      self.scope.last  = index == c.length - 1
      value = self.render_value(if self.value_wrapper then self.value_wrapper.wrap(el, self) else el)
      value = if fn then fn.call(self, value, index) else value
      index++
      result.push value
  
    if _first?
      self.scope.first = _first
    else
      delete self.scope.first
    if _last?
      self.scope.last  = _last
    else
      delete self.scope.last

    result.join("")

  render_object: (obj) ->
    if obj || obj == 0
      if @has_children()
        return @enclosing.render(if typeof(obj) == 'object' then obj else {value: obj})
      else if typeof(obj) == 'object' && 'html' of obj
        value = obj.html && (if obj.html.call then obj.html.call(obj, @render_options()) else obj.html)
        return value or (if value == 0 then value else '')

      return if @options.escape == "false" then obj.toString() else escapeHtml(obj.toString())

  render_function: (value) ->
    options = @render_options()

    self = this
    enclosing_wrapper =
      render: ->
        @rendered = true
        self.enclosing.render.apply(self.enclosing, arguments)
      skip: ->
        @rendered = true
      tags: (filter) -> self.tags(filter)

    @scope.lookup = (name) ->
      tag = self
      while tag
        return tag.scope[name] if tag.scope[name]
        tag = tag.parent
      
      return undefined

    result = value.call(@_tag_fn_scope || value, options, enclosing_wrapper, @scope)
    result = @value_wrapper.wrap(result, this) if @value_wrapper
    if enclosing_wrapper.rendered then result else @render_value(result)

  render_boolean: (value) ->
    if @enclosing.is_empty()
      value.toString()
    else if (value)
      @enclosing.render(@scope) or @default_value()
    else
      @default_value()

  render_value: (value) ->
    return @render_collection(value) || @default_value() if value and value.forEach
    return @render_boolean(value)  if value == true or value == false
    return @render_function(value) if value and value.call

    val = @render_object(value)
    val or (if val == 0 then val else @default_value())

  render_region: (block) ->
    return if block then block.render(@scope) else @enclosing.render()

  with_filters: (value) ->
    if @filters.length
      for filter in @filters
        value = filter(value, @render_options())
    value

  render: (scope) ->
    @scope = scope || {}

    if @no_tag
      return if @no_tag == @parent.last_empty then @enclosing.render(@scope) else ''
    else
      @parent.last_empty = null

    if @include_tag && @options.template.render
      template_name = @options.template.render(@scope)
      @enclosing = new Template(
        name: template_name
        read: @read
        require: @require
        filters: @ast.filters
      ).compile()
      @enclosing.parent = this

    if @layout_tag && @options.name.render
      layout_name = @options.name.render(@scope)

      @enclosing = new Template(
        name: "layouts/#{layout_name}"
        read: @read
        require: @require
        filters: @ast.filters
      ).compile()
      @enclosing.parent = this

    return @enclosing.render(@scope) if @include_tag || @layout_tag || @block_tag

    return this.render_region(@get_block()) if @region_tag

    wrap(
      @with_filters(@render_value(@get_value()), @options),
      @get_option('wrap'),
      @get_option('class')
    )

class Template
  constructor: (options) ->
    @read     = options.read
    @require  = options.require
    @template = options.template || this.read(options.name)
    @name     = options.name
    @filters  = options.filters
    @value_wrapper  = options.value_wrapper

  compile: ->
    ast = new Ast(@require, @filters, @value_wrapper)
    new Parser(@read).parse(@template, ast, @name)
    ast.root

  render: (scope) -> @compile().render(scope)

exports.Template = Template
exports.TemplateError = TemplateError

if window?
  window.PopTags = {Template: Template, escapeHtml: escapeHtml}
