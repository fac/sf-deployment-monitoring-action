module Deployment
  module Events
    class LambdaFunctionFailed
      def initialize(event)
        @event = event
        @error_message = JSON.parse(@event.lambda_function_failed_event_details.cause)['errorMessage']
      end

      def error
        if preflight_checks_failed?
          "The following pre-flight checks have failed: #{preflight_checks_failed.join(', ')}. "\
          'See https://www.notion.so/freeagent/Deployment-Playbooks-aa0f91db24954b328ebfc7d87963a185#3193a48ea76e46b29a38027150612b0d'
        else
          @error_message
        end
      end

      private

      def preflight_checks_failed?
        @error_message.include? 'Pre flight checks failed'
      end

      def preflight_checks_failed
        preflight_checks_output.select { |_k, v| v == 'FAILED' }.keys.sort
      end

      def preflight_checks_output
        # This is horrible and dangerous but we control the input from the lambda. Ideally we should fix there but for now.
        eval(@error_message.split("\n")[1])['Checks']
      end
    end
  end
end
