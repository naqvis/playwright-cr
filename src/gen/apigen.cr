require "json"
require "compiler/crystal/tools/formatter"
require "./types"

module PlaywrightGen
  # :nodoc:
  abstract class Element
    getter json_name : String
    getter json_path : String
    getter json_element : JSON::Any?
    getter parent : Element?

    def initialize(@parent, use_parent_path : Bool, @json_element)
      @json_name = ""
      if (elem = @json_element) && (elem.as_h?)
        @json_name = elem["name"].as_s
      end
      if use_parent_path
        @json_path = @parent.not_nil!.json_path
      else
        @json_path = @parent.nil? ? @json_name : @parent.not_nil!.json_path + "." + @json_name
      end
    end

    def initialize(parent : Element? = nil, element : JSON::Any? = nil)
      initialize(parent, false, element)
    end

    def type_scope
      parent.not_nil!.type_scope
    end

    def write_comments(output : IO, offset : String, text : String)
      return if text.blank?
      lines = text.split("\n")
      lines.each do |line|
        output << (offset + " # " + (line
          .gsub("*/", "")))
        # .gsub(/`([^`]+)`/,"`#{$1}`")))
        output << "\n"
      end
    end

    def formatted_comment
      comment
        .gsub(/```((?<!`)`(?!`)|[^`])+```/, "")
        .gsub(/\\nAn example of[^\\n]+\\n/, "")
        .gsub(/\\nThis example of[^\\n]+\\n/, "")
        .gsub(/\\nSee ChromiumBrowser[^\n]+/, "")
        .gsub(/\\n\\n/, "\n")
    end

    def comment
      (json_element.try &.["comment"]?.try &.as_s?) || ""
    end
  end

  # Represents return type of a method, type of a method param or type of a field
  # :nodoc:
  class TypeRef < Element
    getter custom_type : String = ""
    getter nested_class : Bool = false
    getter is_optional : Bool = false

    def initialize(parent : Element?, element : JSON::Any?)
      super(parent, true, element)
      create_custom_type
    end

    private def to_title(name : String)
      return name if name.blank?
      name[0].upcase + name[1..]
    end

    def create_custom_type
      is_enum = json_name.includes?("|\"")
      @is_optional = json_name.includes?("null|")
      is_class = (json_name.gsub("null", "").gsub("|", "") == "Object") || json_name == "Promise<Array<Object>>"
      # Use path to the corresponding method, param of field as the key.
      parent_path = parent.not_nil!.json_path

      is_class = true if (json_name == "Array<Object>") && (json_path == "BrowserContext.addCookies.cookies")
      is_class = true if (json_name == "Promise<Object>") && (json_path == "BrowserContext.storageState")

      mapping = TypeDefinition.types.find_for_path(parent_path)
      if mapping.nil?
        raise "Cannot create enum, type mapping is missing for: #{parent_path}" if is_enum
        return unless is_class
        if parent.is_a?(Field)
          @custom_type = to_title(parent.not_nil!.json_name)
        else
          @custom_type = to_title(parent.not_nil!.parent.not_nil!.json_name) + to_title(parent.not_nil!.json_name)
        end
      else
        raise "Unexpected source type for: #{parent_path}. Expected: #{mapping.from}, found: #{json_name}" unless mapping.from == json_name

        @custom_type = mapping.to
        if (cm = mapping.custom_mapping)
          cm.define_types_in(type_scope())
          return
        end
      end
      if (is_enum)
        type_scope().create_enum(@custom_type, json_name)
      elsif is_class
        type_scope().create_nested_class(@custom_type, self, json_element)
        @nested_class = true
      end
    end

    def to_crystal
      return "#{custom_type}#{"?" if is_optional && !custom_type.starts_with?("Deferred") && custom_type[-1] != '?'}" unless custom_type.blank?
      return "Nil" if json_element.nil? || (json_element.try &.as_nil rescue nil)

      # convert optional field to boxed types.
      return "Int32" if json_name == "number"
      return "Bool" if json_name == "boolean"
      return "String" if json_name == "string"
      raise "Missing mapping for type union: #{json_path}: #{json_name}" if json_name.gsub("null|", "").includes?("|")
      resp = convert_builtin_type(strip_promise(json_name))
      (resp.nil? || resp.try &.blank?) ? "Nil" : resp
    end

    private def strip_promise(type : String)
      return "Nil" if "Promise" == type
      if type.starts_with?("Promise<")
        return type["Promise<".size...type.size - 1]
      end
      type
    end

    private def convert_builtin_type(type : String)
      val = type.gsub("Array<", "Array(")
        .gsub("Object<", "Hash(")
        .gsub("Map<", "Hash(")
        .gsub("<", "(")
        .gsub(">", ")")
        .gsub("number", "Int32")
        .gsub("string", "String")
      if val.starts_with?("null|")
        val = val.gsub("null|", "")
        val += "?"
      end
      val
    end
  end

  # :nodoc:
  abstract class TypeDefinition < Element
    getter enums : Array(IEnum)
    getter classes : Array(NestedClass)

    class_getter types = Types.new

    def initialize(parent : Element?, element : JSON::Any?)
      @enums = Array(IEnum).new
      @classes = Array(NestedClass).new
      super(parent, element)
    end

    def initialize(parent : Element?, use_parent_path : Bool, element : JSON::Any?)
      @enums = Array(IEnum).new
      @classes = Array(NestedClass).new
      super(parent, use_parent_path, element)
    end

    def type_scope
      self
    end

    def create_enum(nam : String, values)
      add_enum(IEnum.new(self, nam, values))
    end

    def add_enum(en)
      enums.each do |e|
        return if e.name == en.name
      end
      enums << en
    end

    def create_nested_class(name, parent, obj)
      classes.each do |c|
        return if c.name == name
      end

      classes << NestedClass.new(parent, name, obj)
    end

    def write(output : IO, offset : String)
      enums.each do |e|
        e.write(output, offset)
      end
      classes.each do |c|
        c.write(output, offset)
      end
    end
  end

  # :nodoc:
  class Event < Element
    def initialize(parent, element)
      super(parent, element)
      @type = TypeRef.new(self, element["type"])
    end

    def type
      @type
    end
  end

  # :nodoc:
  class Method < Element
    getter return_type : TypeRef?
    getter params : Array(Param) = Array(Param).new
    getter name : String = ""

    @@ts_to_cr_method_name = {
      "$eval"  => "eval_on_selector",
      "$$eval" => "eval_on_selector_all",
      "$"      => "query_selector",
      "$$"     => "query_selector_all",
    } of String => String

    @@custom_signature = {
      "Page.setViewportSize" => ["abstract def set_viewport_size(width : Int32, height : Int32)"],
      # The method is deprecated in ts, just remove it in Crystal
      "BrowserContext.setHTTPCredentials" => [] of String,
      # No connect for now.
      "BrowserType.connect"      => [] of String,
      "BrowserType.launchServer" => [] of String,
      # We don't expose Chromium-Specific APIs at the moment.
      "Page.coverage"        => [] of String,
      "BrowserContext.route" => [
        "abstract def route(url : String, handler : Consumer(Route))",
        "abstract def route(url : Regex, handler : Consumer(Route))",
        "abstract def route(url : (String) -> Bool, handler : Consumer(Route))",
      ],

      "Response.json"        => [] of String,
      "Request.postDataJSON" => [] of String,
      "Page.frame"           => [
        "abstract def frame_by_name(name : String) : Frame?",
        "abstract def frame_by_url(glob : String) : Frame?",
        "abstract def frame_by_url(pattern : Regex) : Frame?",
        "abstract def frame_by_url(predicate : (String) -> Bool) : Frame?",
      ],
      "Page.route" => [
        "abstract def route(url : String, handler : Consumer(Route))",
        "abstract def route(url : Regex, handler : Consumer(Route))",
        "abstract def route(url : (String) -> Bool, handler : Consumer(Route))",
      ],
      "BrowserContext.unroute" => [
        "def unroute(url : String); unroute(url,nil);end",
        "def unroute(url : Regex); unroute(url,nil);end",
        "def unroute(url : (String) -> Bool); unroute(url,nil);end",
        "abstract def unroute(url : String, handler : Consumer(Route)?)",
        "abstract def unroute(url : Regex, handler : Consumer(Route)?)",
        "abstract def unroute(url : (String) -> Bool, handler : Consumer(Route)?)",
      ],
      "Page.unroute" => [
        "def unroute(url : String); unroute(url,nil);end",
        "def unroute(url : Regex); unroute(url,nil);end",
        "def unroute(url : (String) -> Bool); unroute(url,nil);end",
        "abstract def unroute(url : String, handler : Consumer(Route)?)",
        "abstract def unroute(url : Regex, handler : Consumer(Route)?)",
        "abstract def unroute(url : (String) -> Bool, handler : Consumer(Route)?)",
      ],
      "BrowserContext.cookies" => [
        "def cookies; cookies(Array(String).new);end",
        "def cookies(url : String); cookies([url]);end",
        "abstract def cookies(url : Array(String)) : Array(Cookie)",
      ],
      "BrowserContext.addCookies" => [
        "abstract def add_cookies(cookies : Array(AddCookie))",
      ],
      "FileChooser.setFiles" => [
        "def set_files(file : Path); set_files(file,nil);end",
        "def set_files(file : Path, options : SetFilesOptions?); set_files([file],options);end",
        "def set_files(files : Array(Path)); set_files(files,nil);end",
        "abstract def set_files(file : Array(Path), options : SetFilesOptions?)",

        "def set_files(file : FileChooser::FilePayload); set_files(file,nil);end",
        "def set_files(file : FileChooser::FilePayload, options : SetFilesOptions?); set_files([file],options);end",
        "def set_files(files : Array(FileChooser::FilePayload)); set_files(files,nil);end",
        "abstract def set_files(file : Array(FileChooser::FilePayload), options : SetFilesOptions?)",
      ],
      "ElementHandle.setInputFiles" => [
        "def set_input_files(file : Path); set_input_files(file,nil);end",
        "def set_input_files(file : Path, options : SetInputFilesOptions?); set_input_files([file],options);end",
        "def set_input_files(files : Array(Path)); set_input_files(files,nil);end",
        "abstract def set_input_files(file : Array(Path), options : SetInputFilesOptions?)",

        "def set_input_files(file : FileChooser::FilePayload); set_input_files(file,nil);end",
        "def set_input_files(file : FileChooser::FilePayload, options : SetInputFilesOptions?); set_input_files([file],options);end",
        "def set_input_files(files : Array(FileChooser::FilePayload)); set_input_files(files,nil);end",
        "abstract def set_input_files(file : Array(FileChooser::FilePayload), options : SetInputFilesOptions?)",
      ],
    } of String => Array(String)

    inputfiles_with_selector = [
      "def set_input_files(selector : String, file : Path); set_input_files(selector, file,nil);end",
      "def set_input_files(selector : String, file : Path, options : SetInputFilesOptions?); set_input_files(selector, [file],options);end",
      "def set_input_files(selector : String, files : Array(Path)); set_input_files(selector, files,nil);end",
      "abstract def set_input_files(selector : String, file : Array(Path), options : SetInputFilesOptions?)",

      "def set_input_files(selector : String, file : FileChooser::FilePayload); set_input_files(selector, file,nil);end",
      "def set_input_files(selector : String, file : FileChooser::FilePayload, options : SetInputFilesOptions?); set_input_files(selector, [file],options);end",
      "def set_input_files(selector : String, files : Array(FileChooser::FilePayload)); set_input_files(selector, files,nil);end",
      "abstract def set_input_files(selector : String, file : Array(FileChooser::FilePayload), options : SetInputFilesOptions?)",
    ]

    @@custom_signature["Page.setInputFiles"] = inputfiles_with_selector
    @@custom_signature["Frame.setInputFiles"] = inputfiles_with_selector

    wait_for_event = [
      %q(
        def wait_for_event(event : EventType) : Deferred(Event(EventType))
          wait_for_event(event, nil)
        end
      ),
      %q(
        def wait_for_event(event : EventType, predicate : ((Event(EventType)) -> Bool)) : Deferred(Event(EventType))
          options = WaitForEventOptions.new
          options.predicate = predicate
          wait_for_event(event, options)
        end
      ),
      "abstract def wait_for_event(event : EventType, options : WaitForEventOptions?) : Deferred(Event(EventType))",
    ]
    @@custom_signature["Page.waitForEvent"] = wait_for_event
    @@custom_signature["BrowserContext.waitForEvent"] = wait_for_event
    @@custom_signature["WebSocket.waitForEvent"] = wait_for_event

    @@custom_signature["Page.waitForRequest"] = [
      %q(
        def wait_for_request(url_glob : String) : Deferred(Request?)
          wait_for_request(url_glob,nil)
        end
      ),
      %q(
        def wait_for_request(url_pattern : Regex) : Deferred(Request?)
          wait_for_request(url_pattern,nil)
        end
      ),
      %q(
        def wait_for_request(predicate : (String -> Bool)?) : Deferred(Request?)
          wait_for_request(predicate,nil)
        end
      ),
      %q(
        abstract def wait_for_request(url_glob : String, options : WaitForRequestOptions?) : Deferred(Request?)
      ),
      %q(
        abstract def wait_for_request(url_pattern : Regex, options : WaitForRequestOptions?) : Deferred(Request?)
      ),
      %q(
        abstract def wait_for_request(predicate : (String -> Bool)?, options : WaitForRequestOptions?) : Deferred(Request?)
      ),
    ]

    @@custom_signature["Page.waitForResponse"] = [
      %q(
        def wait_for_response(url_glob : String) : Deferred(Response?)
          wait_for_response(url_glob,nil)
        end
      ),
      %q(
        def wait_for_response(url_pattern : Regex) : Deferred(Response?)
          wait_for_response(url_pattern,nil)
        end
      ),
      %q(
        def wait_for_response(predicate : (String -> Bool)?) : Deferred(Response?)
          wait_for_response(predicate,nil)
        end
      ),
      %q(
        abstract def wait_for_response(url_glob : String, options : WaitForResponseOptions?) : Deferred(Response?)
      ),
      %q(
        abstract def wait_for_response(url_pattern : Regex, options : WaitForResponseOptions?) : Deferred(Response?)
      ),
      %q(
        abstract def wait_for_response(predicate : (String -> Bool)?, options : WaitForResponseOptions?) : Deferred(Response?)
      ),
    ]

    select_options = [
      "def select_option(selector : String, value : String)
        select_option(selector,value,nil)
      end",
      "def select_option(selector : String, value : String, options : SelectOptionOptions?)
        select_option(selector,[value],nil)
      end",
      "def select_option(selector : String, values : Array(String))
        select_option(selector,values,nil)
      end",
      "def select_option(selector : String, values : Array(String),options : SelectOptionOptions?)
        if values.size == 0
          return select_option(selector,ElementHandle::SelectOption.new,options)
        end
        select_option(selector, values.map{|v|ElementHandle::SelectOption.new(v)}.to_a, options)
      end",
      "def select_option(selector : String, value : ElementHandle::SelectOption?)
        select_option(selector,value,nil)
       end",
      "def select_option(selector : String, value : ElementHandle::SelectOption?, options : SelectOptionOptions?)
        select_option(selector,value.nil? ? nil : [value],options)
      end",
      "def select_option(selector : String, values : Array(ElementHandle::SelectOption)?)
      select_option(selector,values,nil)
     end",
      "abstract def select_option(selector : String, values : Array(ElementHandle::SelectOption)?, options : SelectOptionOptions?)",
      %q(
      def select_option(selector : String, value : ElementHandle?)
        select_option(selector,value,nil)
      end
    ),
      %q(
      def select_option(selector : String, value : ElementHandle?, options : SelectOptionOptions?)
        select_option(selector,value.nil? ? nil : [value],options)
      end
    ),
      %q(
      def select_option(selector : String, values : Array(ElementHandle)?)
        select_option(selector,values,nil)
      end
    ),
      %q(
      abstract def select_option(selector : String, values : Array(ElementHandle)?, options : SelectOptionOptions?)
    ),
    ]

    @@custom_signature["Page.selectOption"] = select_options
    @@custom_signature["Frame.selectOption"] = select_options
    @@custom_signature["ElementHandle.selectOption"] = select_options.map do |s|
      s.gsub("selector : String, ", "")
        .gsub("(selector,", "(")
        .gsub("ElementHandle::", "")
    end.to_a
    @@custom_signature["Selectors.register"] = [
      %q(
        def register(name : String, script : String)
          register(name,script,nil)
        end
      ),
      %q(
        abstract def register(name : String, script : String, options : RegisterOptions?)
      ),
      %q(
        def register(name : String, path : Path)
          register(name,path,nil)
        end
      ),
      %q(
        abstract def register(name : String, path : Path, options : RegisterOptions?)
      ),
    ]
    @@skip_comments = Set{
      "BrowserContext.waitForEvent.optionsOrPredicate",
      "Page.waitForEvent.optionsOrPredicate",
      "WebSocket.waitForEvent.optionsOrPredicate",
      "Page.frame.options",
      "Page.waitForRequest",
      "Page.waitForResponse",
    }

    def initialize(parent : TypeDefinition?, element : JSON::Any?)
      super(parent, element)
      if (@@custom_signature[json_path]?.try &.size == 0)
        @return_type = nil
      else
        @return_type = TypeRef.new(self, element["type"])
        if (args = element["args"]?)
          args.as_h.each do |_, v|
            params << Param.new(self, v)
          end
        end
      end
      @name = (@@ts_to_cr_method_name[json_name]? || json_name).underscore
    end

    private def to_crystal
      first = true
      str = String.build do |sb|
        params.each do |p|
          sb << ", " unless first
          sb << p.to_crystal
          first = false
        end
      end

      "abstract def #{@name}(#{str}) " + (@return_type.nil? ? "" : " : #{@return_type.not_nil!.to_crystal}") + "\n"
    end

    def write(output : IO, offset : String)
      if (signatures = @@custom_signature[json_path]?)
        signatures.each_with_index do |s, i|
          if i == signatures.size - 1
            write_comments(output, offset)
          end
          output << offset + s + "\n"
        end
        return
      end

      (params.size - 1).downto(0) do |i|
        break unless params[i].optional?
        write_default_overloaded_method(i, output, offset)
        write_splat_overloaded_method(i, output, offset)
      end
      write_comments(output, offset)
      output << offset + to_crystal
    end

    def write_default_overloaded_method(idx, output, offset)
      args = ""
      paras = String.build do |plist|
        args = String.build do |alist|
          0.upto(idx - 1) do |i|
            p = params[i]
            plist << ", " if plist.bytesize > 0
            alist << ", " if plist.bytesize > 0
            plist << p.to_crystal
            alist << p.name
          end
          alist << ", " if alist.bytesize > 0
          alist << ("int" == params[idx].type.try &.to_crystal ? "0" : "nil")
        end
      end
      output << offset + "def #{name}(#{paras}) : #{return_type.try &.to_crystal}\n"
      output << offset + "   #{name}(#{args})\n"
      output << offset + "end\n"
    end

    def write_splat_overloaded_method(idx, output, offset)
      return unless params[idx].type.try &.to_crystal.starts_with?("Array(")
      args = ""
      paras = String.build do |plist|
        args = String.build do |alist|
          0.upto(idx - 1) do |i|
            p = params[i]
            plist << ", " if plist.bytesize > 0
            alist << ", " if plist.bytesize > 0
            plist << p.to_crystal
            alist << p.name
          end
          plist << ", " if plist.bytesize > 0
          plist << "*#{params[idx].to_crystal.gsub("Array(", "").gsub(")", "").gsub("?", "")}"
          alist << ", " if alist.bytesize > 0
          alist << "#{params[idx].name}.to_a"
        end
      end
      output << offset + "def #{name}(#{paras}) : #{return_type.try &.to_crystal}\n"
      output << offset + "   #{name}(#{args})\n"
      output << offset + "end\n"
    end

    def write_comments(output : IO, offset : String)
      return if @@skip_comments.includes?(json_path)
      write_comments(output, offset, formatted_comment)
    end
  end

  # :nodoc:
  class Param < Element
    getter type : TypeRef?
    @@custom_name = {
      "Keyboard.type.options"  => "delay",
      "Keyboard.press.options" => "delay",
    } of String => String

    def initialize(method, element)
      super(method, element)
      @type = TypeRef.new(self, element["type"])
    end

    def optional?
      return true if json_element.nil?
      !json_element.not_nil!["required"].as_bool
    end

    def name
      nam = @@custom_name[json_path]?
      return nam unless nam.nil?
      json_name.underscore
    end

    def to_crystal
      ftype = (type.nil? ? "" : " : " + (type.not_nil!.to_crystal || ""))
      ftype = ftype.blank? ? ftype : (ftype + "#{"?" if optional? && ftype != " : Any"}")
      name + ftype
    end
  end

  # :nodoc:
  class Field < Element
    getter name : String
    getter type : TypeRef?
    getter required : Bool

    def initialize(parent, @jname : String, element)
      super(parent, element)
      @name = @jname.underscore

      if element.nil?
        @required = false
      else
        @required = element.not_nil!["required"].as_bool
      end

      @type = TypeRef.new(self, element["type"])
    end

    def write(output : IO, offset : String, access : Bool)
      write_comments(output, offset, formatted_comment)
      ftype = access ? "property" : "getter"
      if ["Frame.waitForNavigation.options.url", "Page.waitForNavigation.options.url"].includes?(json_path)
        output << offset + %(
          @[JSON::Field(key: "#{@jname}")]
          #{ftype} #{name} : #{type.try &.to_crystal} #{"?" unless required}
          @[JSON::Field(ignore: true)]
          getter(glob : String?){url.as?(String)}
          @[JSON::Field(ignore: true)]
          getter(pattern : Regex?){url.as?(Regex)}
          @[JSON::Field(ignore: true)]
          getter(predicate : (String -> Bool)?){url.as?(Proc(String,Bool))}
        )
        return
      end
      if ["Frame.waitForFunction.options.polling", "Page.waitForFunction.options.polling"].includes?(json_path)
        output << offset + %q(
          @[JSON::Field(key: "pollingInterval")]
          property polling : Int32?
        )
        output << "\n"
        return
      end
      if "Route.fulfill.response.body" == json_path
        output << offset + %q(
          @[JSON::Field(ignore: true)]
          property body : String = ""
          @[JSON::Field(ignore: true)]
          property body_bytes : Bytes = Bytes.empty
        ) << "\n"
        return
      end

      if ["Browser.newContext.options.storageState", "Browser.newPage.options.storageState"].includes?(json_path)
        output << offset + "@[JSON::Field(key: \"#{@jname}\")]\n#{ftype} #{name} : #{type.try &.to_crystal}?\n"
        output << offset + "@[JSON::Field(ignore: true)]\n#{ftype} #{name}_path : Path?\n"
        return
      end

      ignore = type.try &.to_crystal == "Logger" ? ",ignore: true" : ""
      output << offset + "@[JSON::Field(key: \"#{@jname}\"#{ignore})]\n"
      output << offset + "#{ftype} #{name} : #{type.try &.to_crystal}#{"?" if !required && !type.try &.to_crystal.ends_with?("?")}\n"
    end

    def write_builder_method(output : IO, offset : String, parent_cls : String)
      if ["Frame.waitForNavigation.options.url", "Page.waitForNavigation.options.url"].includes?(json_path)
        output << offset + %q(
          def glob=(val : String?)
            @url = val
          end

          def pattern=(val : Regex?)
            @url = val
          end

          def predicate=(val : (String -> Bool)?)
            @url = val
          end
        ) << "\n"
        return
      end

      if ["Frame.waitForFunction.options.polling", "Page.waitForFunction.options.polling"].includes?(json_path)
        output << offset + %q(
          def with_request_animation_frame
            @polling = nil
            self
          end

          def with_polling_interval(millis : Int32)
            @polling = millis
            self
          end
        ) << "\n"
        return
      end

      if ["Page.click.options.position",
          "Page.dblclick.options.position",
          "Page.hover.options.position",
          "Frame.click.options.position",
          "Frame.dblclick.options.position",
          "Frame.hover.options.position",
          "ElementHandle.click.options.position",
          "ElementHandle.dblclick.options.position",
          "ElementHandle.hover.options.position"].includes?(json_path)
        output << offset + "def with_position(position : Position) : #{parent_cls}
          self.position = position
          self
        end

        def with_position(x : Int32, y : Int32) : #{parent_cls}
          with_position(Position.new(x,y))
        end
        " + "\n"
        return
      end

      if ["Browser.newContext.options.storageState",
          "Browser.newPage.options.storageState"].includes?(json_path)
        output << offset + %q(
          def with_storage_state(state : BrowserContext::StorageState)
            self.storage_state = state
            self.storage_state_path = nil
            self
          end
          def with_storage_state(path : Path)
            self.storage_state = nil
            self.storage_state_path = path
            self
          end
        )
        output << "\n"
        return
      end

      if json_path == "Route.continue.overrides.postData"
        output << offset + %q(
          def with_post_data(data : String)
            self.post_data = data.to_slice
            self
          end
        )
        return
      end
    end
  end

  # :nodoc:
  class NestedClass < TypeDefinition
    getter name : String
    getter fields : Array(Field)

    @@deprecated_options = Set{
      "Browser.newPage.options.videosPath",
      "Browser.newPage.options.videoSize",
      "Browser.newContext.options.videosPath",
      "Browser.newContext.options.videoSize",
      "BrowserType.launchPersistentContext.options.videosPath",
      "BrowserType.launchPersistentContext.options.videoSize",
    }

    def initialize(parent, @name, element)
      @fields = Array(Field).new
      super(parent, true, element)
      if (p = element.try &.["properties"]?)
        p.as_h.each do |k, v|
          next if @@deprecated_options.includes?("#{json_path}.#{k}")
          fields << Field.new(self, k, v)
        end
      end
    end

    def write(output : IO, offset : String)
      write_comments(output, offset, formatted_comment)
      output << offset + "class #{name}\n"
      body_offset = offset + "  "
      output << body_offset + "include JSON::Serializable\n"
      super(output, body_offset)

      is_return_type = (parent.try &.parent.is_a?(Method)) || false
      field_access = is_return_type ? false : true
      fields.each do |f|
        f.write(output, body_offset, field_access)
      end
      output << "\n"
      required = fields.select(&.required)
      optional = fields.reject(&.required)
      args = Array(String).new
      required.each do |f|
        args << "@#{f.name}"
      end
      optional.each do |f|
        args << "@#{f.name} = nil"
      end
      output << offset + "def initialize(#{args.join(",")})\n"
      output << "end\n"
      if is_return_type
        # fields.each do |f|
        #   f.write_getter(output, body_offset)
        # end
      else
        write_builder_methods(output, body_offset)
      end
      output << offset + "end\n"
    end

    def write_builder_methods(output : IO, offset : String)
      fields.each do |f|
        f.write_builder_method(output, offset, name)
      end
    end
  end

  # :nodoc:
  class Interface < TypeDefinition
    getter methods : Array(Method)
    getter events : Array(Event)

    @@allowed_base_interfaces = Set{"Browser", "JSHandle", "BrowserContext"}

    def initialize(element)
      super(nil, element)
      @methods = Array(Method).new
      @events = Array(Event).new

      element["methods"].as_h.each do |_, v|
        methods << Method.new(self, v)
      end

      element["properties"].as_h.each do |_, v|
        methods << Method.new(self, v)
      end

      element["events"].as_h.each do |_, v|
        events << Event.new(self, v)
      end
    end

    def write(output : IO, offset : String)
      extends = ""
      if base = json_element.try &.["extends"]?
        extends = " include #{base}" if @@allowed_base_interfaces.includes?(base)
      end

      if ["Page", "Frame", "ElementHandle", "FileChooser", "Browser", "BrowserContext", "BrowserType", "Download", "Route", "Selectors"].includes?(json_name)
        output << %q(require "path")
        output << "\n"
      end
      if ["Page", "Frame", "BrowserContext"].includes?(json_name)
        output << %q(require "regex")
        output << "\n"
      end
      unless extends.blank?
        output << "require \"./#{extends.gsub("include", "").lstrip.downcase}\"\n"
      end
      output << %q(require "json") << "\n"
      output << "module Playwright\n"

      write_comments(output, offset, formatted_comment)
      output << " module #{json_name}\n"
      output << "#{extends}\n" unless extends.blank?
      offset = "  "
      write_shared_types(output, offset)
      write_events(output, offset)
      super(output, offset)
      methods.each do |m|
        m.write(output, offset)
      end
      output << offset + %q(abstract def wait_for_event(event : EventType) : Deferred(Event(EventType))) + "\n" if json_name == "Worker"
      output << "end\n"
      output << "end\n"
    end

    def write_events(output : IO, offset : String)
      return if events.empty?
      output << offset + "enum EventType\n"
      events.each do |e|
        output << offset + " " + e.json_name.upcase + "\n"
      end
      output << "end\n"
      output << "\n"
      output << %q(abstract def add_listener(type : EventType, listener : Listener(EventType))) + "\n"
      output << %q(abstract def remove_listener(type : EventType, listener : Listener(EventType))) + "\n"
    end

    def write_shared_types(output : IO, offset : String)
      case json_name
      when "Dialog"
        output << %q(
          enum Type
            ALERT
            BEFOREUNLOAD
            CONFIRM
            PROMPT

            def to_s
              super.downcase
            end

            def to_json(json : JSON::Builder)
              json.string(to_s)
            end
          end
        )
        output << "\n"
      when "Mouse"
        output << %q(
          enum Button
            LEFT
            MIDDLE
            RIGHT

            def to_s
              super.downcase
            end

            def to_json(json : JSON::Builder)
              json.string(to_s)
            end
          end
        )
        output << "\n"
      when "Keyboard"
        output << %q(
          enum Modifier
            ALT
            CONTROL
            META
            SHIFT

            def to_s
              super.capitalize
            end

            def to_json(json : JSON::Builder)
              json.string(to_s)
            end
          end
        )
        output << "\n"
      when "Page"
        output << %q(
          class ViewPort
              include JSON::Serializable

              getter width : Int32
              getter height : Int32

              def initialize(@width, @height)
              end
          end
        )
        output << "\n"
        output << %q(
          module Function
            abstract def call(args : Array(Any)) : Any

            def call(*args : Any) : Any
              call(args.to_a)
            end
          end
        )
        output << "\n"
        output << %q(
          module Binding
            module Source
              abstract def context : BrowserContext?
              abstract def page : Page?
              abstract def frame : Frame
            end

            abstract def call(source : Source, args : Array(Any)) : Any

            def call(source : Source, *args : Any) : Any
              call(source, args.to_a)
            end
          end
        )
        output << "\n"
        output << %q(
          module Error
            abstract def message : String
            abstract def name : String
            abstract def stack : String
          end
        )
        output << "\n"
      when "BrowserContext"
        output << %q(
          enum SameSite
            STRICT
            LAX
            NONE

            def to_s
              super.capitalize
            end

            def to_json(json : JSON::Builder)
              json.string(to_s)
            end
          end
        )
        output << "\n"
        output << %q(
          class HTTPCredentials
            include JSON::Serializable
            getter username : String
            getter password : String

            def initialize(@username, @password)
            end
          end

          class StorageState
            include JSON::Serializable
            property cookies : Array(AddCookie)
            property origins : Array(OriginState)

            class OriginState
              include JSON::Serializable
              getter origin : String
              @[JSON::Field(key: "localStorage")]
              property local_storage : Array(LocalStorageItem)

              class LocalStorageItem
                include JSON::Serializable
                getter name : String
                getter value : String

                def initialize(@name, @value)
                end
              end

              def initialize(@origin, @local_storage = Array(LocalStorageItem).new)
              end
            end

            def initialize
              @cookies = Array(AddCookie).new
              @origins = Array(OriginState).new
            end
          end
        ) << "\n"
      when "Browser"
        output << %q(
          class VideoSize
            include JSON::Serializable
            getter width : Int32
            getter height : Int32

            def initialize(@width, @height)
            end
          end
        ) << "\n"
      when "ElementHandle"
        output << %q(
            class BoundingBox
              include JSON::Serializable
                property x : Float64?
                property y : Float64?
                property width : Float64?
                property height : Float64?

                def initialize(@x = nil, @y = nil, @width = nil, @height = nil)
                end
            end

            class SelectOption
                include JSON::Serializable
                property value : String?
                property label : String?
                property index : Int32?

                def initialize(@value = nil, @label = nil, @index = nil)
                end
            end
          ) << "\n"
      when "FileChooser"
        output << %q(
              class FilePayload
                include JSON::Serializable
                getter name : String
                getter mime_type : String
                getter buffer : Bytes

                def initialize(@name, @mime_type, @buffer)
                end
              end
            ) << "\n"
      when "WebSocket"
        output << %q(
                module FrameData
                  abstract def body : Bytes
                  abstract def text : String
                end
              ) << "\n"
      end
      if ["Page", "BrowserContext", "WebSocket"].includes?(json_name)
        output << %q(
          class WaitForEventOptions
            property timeout : Int32?
            property predicate : ((Event(EventType)) -> Bool) | Nil

            def initialize(@timeout = nil, @predicate = nil)
            end
          end
        ) << "\n"
      end
    end
  end

  # :nodoc:
  class IEnum < TypeDefinition
    getter name : String
    getter enum_values : Array(String)

    def initialize(parent, name : String, values)
      @name = name
      super(parent, nil)
      @has_hyphen = !values.index("-").nil?
      split = values.split("|")
      @enum_values = split.map { |s| s.gsub("-", "_").gsub("\"", "").upcase }.to_a
    end

    def write(output : IO, offset : String)
      output << offset + "enum #{name}\n"
      output << enum_values.join("\n") << "\n"
      output << %(
        def to_s
          super.downcase#{@has_hyphen ? ".gsub(\"_\",\"-\")" : ""}
        end
        def to_json(json : JSON::Builder)
          json.string(to_s)
        end
      ) << "\n"
      output << "end\n"
    end
  end

  # :nodoc:
  class ApiGenerator
    private SKIP_LIST = [
      "BrowserServer",
      "ChromiumBrowser",
      "ChromiumBrowserContext",
      "ChromiumCoverage",
      "CDPSession",
      "FirefoxBrowser",
      "WebKitBrowser",
    ]

    def initialize(reader : IO)
      api = JSON.parse(reader)
      api.as_h.each do |k, v|
        next if SKIP_LIST.includes?(k)
        itf = Interface.new(v)
        str = String.build do |sb|
          itf.write(sb, " ")
        end
        cwd = Path[__DIR__]
        filename = "#{cwd.parent}/playwright/#{k.downcase}.cr"
        puts "Generating : #{k.downcase}.cr"
        fmt = Crystal.format(str, filename: filename)
        File.write(filename, fmt)
      end
    end
  end
end

file = ARGV[0]?
if !file
  puts "Missing argument"
  exit(1)
end
if !File.exists?(file.not_nil!)
  puts "File not found [#{file}]"
  exit(1)
end
File.open(file.not_nil!) do |f|
  PlaywrightGen::ApiGenerator.new(f)
end
