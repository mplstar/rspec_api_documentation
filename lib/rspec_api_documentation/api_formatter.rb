require 'rspec/core/formatters/base_text_formatter'

module RspecApiDocumentation
  class ApiFormatter < RSpec::Core::Formatters::BaseTextFormatter
    RSpec::Core::Formatters.register self, :example_passed, :example_failed, :stop

    def initialize(output)
      super

      output.puts "Generating API Docs"
    end

    def start(notification)
      super

      RspecApiDocumentation.documentations.each(&:clear_docs)
    end

    def example_group_started(notification)
      super

      output.puts "  #{example_group.description}"
    end

    def example_passed(example_notification)
      example = example_notification.example
      output.puts "    * #{example.description}"
      RspecApiDocumentation.documentations.each do |documentation|
        documentation.document_example(example)
      end
    end

    def example_failed(example_notification)
      example = example_notification.example
      output.puts "    ! #{example.description} (FAILED)"
    end

    def stop(notification)
      RspecApiDocumentation.documentations.each(&:write)
    end
  end
end
