require "../filechooser"

module Playwright
  private class FileChooserImpl
    include FileChooser
    getter page : Page
    getter element : ElementHandle
    getter is_multiple : Bool

    def initialize(@page, @element, @is_multiple)
    end

    def set_files(file : Array(Path), options : SetFilesOptions?)
      set_files(Utils.to_file_payload(file), options)
    end

    def set_files(file : Array(FileChooser::FilePayload), options : SetFilesOptions?)
      if o = options
        element.set_input_files(file, ElementHandle::SetInputFilesOptions.from_json(o.to_json))
      else
        element.set_input_files(file, nil)
      end
    end
  end
end
