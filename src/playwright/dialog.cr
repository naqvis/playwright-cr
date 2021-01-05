require "json"

module Playwright
  # Dialog objects are dispatched by page via the page.on('dialog') event.
  # An example of using `Dialog` class:
  #
  module Dialog
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

    def accept : Nil
      accept(nil)
    end

    # Returns when the dialog has been accepted.
    abstract def accept(prompt_text : String?) : Nil
    # If dialog is prompt, returns default prompt value. Otherwise, returns empty string.
    abstract def default_value : String
    # Returns when the dialog has been dismissed.
    abstract def dismiss : Nil
    # A message displayed in the dialog.
    abstract def message : String
    # Returns dialog's type, can be one of `alert`, `beforeunload`, `confirm` or `prompt`.
    abstract def type : Type
  end
end
