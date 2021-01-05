require "regex"
require "json"
require "mime"

module Playwright
  class PageBindingProc
    include Page::Binding

    private alias BindingProc = (Page::Binding::Source, Array(Any)) -> Any
    @func : BindingProc

    def initialize(&block : BindingProc)
      @func = block
    end

    def call(source : Page::Binding::Source, args : Array(Any)) : Any
      @func.call(source, args)
    end
  end

  class PageFunctionProc
    include Page::Function

    private alias FuncProc = (Array(Any)) -> Any
    @func : FuncProc

    def initialize(&block : FuncProc)
      @func = block
    end

    def call(args : Array(Any)) : Any
      @func.call(args)
    end
  end

  struct Consumer(T)
    @func : T ->

    def initialize(&block : T ->)
      @func = block
    end

    def call(value : T)
      @func.call(value)
    end
  end

  class Position
    include JSON::Serializable

    property x : Int32
    property y : Int32

    def initialize(@x, @y)
    end
  end

  class Geolocation
    include JSON::Serializable

    property latitude : Float64
    property longitude : Float64
    property accuracy : Float64?

    def initialize(@latitude, @longitude, @accuracy = nil)
    end

    def self.new(latitude : Int32, longitude : Int32, accuracy : Int32? = nil)
      new(latitude.to_f64, longitude.to_f64, accuracy.try &.to_f64)
    end

    def self.new
      new(0, 0)
    end
  end

  enum ColorScheme
    NULL
    DARK
    LIGHT
    NO_PREFERENCE

    def to_s
      super.downcase.gsub("_", "-")
    end

    def to_json(json : JSON::Builder)
      json.string(to_s)
    end

    def self.parse(string : String) : self
      super(string.gsub("-", "_"))
    end
  end

  private class UrlMatcher
    def self.to_predicate(pattern : Regex)
      ->(s : String) { pattern.matches?(s) }
    end

    def self.any
      new(nil)
    end

    def self.one_of(glob : String?, pattern : Regex?, predicate : (String -> Bool)?) : UrlMatcher
      result = any
      count = 0
      if g = glob
        count += 1
        result = new(g)
      end
      if p = pattern
        count += 1
        result = new(p)
      end
      if pr = predicate
        count += 1
        result = new(pr)
      end

      raise ArgumentError.new("Only one of glob, pattern and predicate can be specified, but found #{count}") if count > 1
      result
    end

    private getter predicate : (String -> Bool)?
    @source : String | Regex | Nil

    def initialize(glob : String)
      @source = glob
      @predicate = UrlMatcher.to_predicate(Regex.new(Utils.glob_to_regex(glob)))
    end

    def initialize(pattern : Regex)
      @source = pattern
      @predicate = UrlMatcher.to_predicate(pattern)
    end

    def initialize(@predicate)
      @source = nil
    end

    def test(value : String)
      return true unless predicate
      predicate.not_nil!.call(value)
    end

    def_equals_and_hash @source
  end

  private module Utils
    extend self
    private ESCAPED_GLOB_CHARS = Set{'/', '$', '^', '+', '.', '(', ')', '=', '!', '|'}

    def to_file_payload(files : Array(Path))
      payloads = Array(FileChooser::FilePayload).new
      files.each do |file|
        buffer = File.read(file)
        payloads << FileChooser::FilePayload.new(file.basename, MIME.from_extension(file.extension, "application/octet-stream"), buffer.to_slice)
      end
      payloads
    end

    def glob_to_regex(glob : String)
      String.build do |sb|
        sb << '^'
        in_group = false
        i = 0
        while i < glob.size
          c = glob[i]
          if ESCAPED_GLOB_CHARS.includes?(c)
            sb << "\\#{c}"
            i += 1
            next
          end

          if c == '*'
            before_deep = i < 1 || glob[i - 1] == '/'
            star_count = 1
            while i + 1 < glob.size && glob[i + 1] == '*'
              star_count += 1
              i += 1
            end
            after_deep = i + 1 >= glob.size || glob[i + 1] == '/'
            is_deep = star_count > 1 && before_deep && after_deep
            if is_deep
              sb << %q(((?:[^\/]*(?:\/|$))*))
              i += 1
            else
              sb << "([^/]*)"
            end
            i += 1
            next
          end
          case c
          when '?' then sb << '.'
          when '{'
            in_group = true
            sb << '('
          when '}'
            in_group = false
            sb << ')'
          when ',' then in_group ? (sb << '|') : (sb << "\\#{c}")
          else
            sb << c
          end
          i += 1
        end
        sb << '$'
      end
    end

    def safe_close_error?(exc : PlaywrightException)
      safe_close_error?(exc.message || "")
    end

    def safe_close_error?(err : String)
      err.includes?("Browser has been closed") || err.includes?("Target page, context or browser has been closed")
    end
  end
end
