require "path"
require "json"

module Playwright
  # FileChooser objects are dispatched by the page in the page.on('filechooser') event.
  #
  module FileChooser
    class FilePayload
      include JSON::Serializable
      getter name : String
      getter mime_type : String
      getter buffer : Bytes

      def initialize(@name, @mime_type, @buffer)
      end
    end

    class SetFilesOptions
      include JSON::Serializable
      # Actions that initiate navigations are waiting for these navigations to happen and for pages to start loading. You can opt out of waiting via setting this flag. You would only need this option in the exceptional cases such as navigating to inaccessible pages. Defaults to `false`.
      @[JSON::Field(key: "noWaitAfter")]
      property no_wait_after : Bool?
      # Maximum time in milliseconds, defaults to 30 seconds, pass `0` to disable timeout. The default value can be changed by using the `browserContext.setDefaultTimeout(timeout)` or `page.setDefaultTimeout(timeout)` methods.
      @[JSON::Field(key: "timeout")]
      property timeout : Int32?

      def initialize(@no_wait_after = nil, @timeout = nil)
      end
    end

    # Returns input element associated with this file chooser.
    abstract def element : ElementHandle
    # Returns whether this file chooser accepts multiple files.
    abstract def is_multiple : Bool
    # Returns page this file chooser belongs to.
    abstract def page : Page

    def set_files(file : Path)
      set_files(file, nil)
    end

    def set_files(file : Path, options : SetFilesOptions?)
      set_files([file], options)
    end

    def set_files(files : Array(Path))
      set_files(files, nil)
    end

    abstract def set_files(file : Array(Path), options : SetFilesOptions?)

    def set_files(file : FileChooser::FilePayload)
      set_files(file, nil)
    end

    def set_files(file : FileChooser::FilePayload, options : SetFilesOptions?)
      set_files([file], options)
    end

    def set_files(files : Array(FileChooser::FilePayload))
      set_files(files, nil)
    end

    # Sets the value of the file input this chooser is associated with. If some of the `filePaths` are relative paths, then they are resolved relative to the the current working directory. For empty array, clears the selected files.
    abstract def set_files(file : Array(FileChooser::FilePayload), options : SetFilesOptions?)
  end
end
