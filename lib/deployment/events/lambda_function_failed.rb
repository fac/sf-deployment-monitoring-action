module Deployment
  module Events
    class LambdaFunctionFailed
      def initialize(event)
        @event = event
        @error_message = JSON.parse(@event.lambda_function_failed_event_details.cause)['errorMessage']
      end

      def error
        if preflight_checks_failed? && forward_deploy_check_failed?
          'Forward deploy check FAILED. No need to panic! '\
          'This likely means your commit has already been deployed as part of a previous deploy. '\
          'To confirm you can check whether your SHA is a parent commit to the currently deployed SHA. '\
          'You can figure out the currently deployed SHA by following this guide https://www.notion.so/freeagent/Deployment-Runbooks-29796221387e40b7abbb217d7d33c4ac?pvs=4#3bfa2ab5d3ab4c33b7a46522027f94bb'
        elsif preflight_checks_failed?
          preflight_checks_output.to_json
        else
          @error_message
        end
      end

      private
      def preflight_checks_failed?
        @error_message.include? 'Pre flight checks failed'
      end

      def preflight_checks_output
        # This is horrible and dangerous but we control the input from the lambda. Ideally we should fix there but for now.
        eval(@error_message.split("\n")[1])["Checks"]
      end

      def forward_deploy_check_failed?
        preflight_checks_output[:ForwardDeployCheck] == 'FAILED'
      end
    end
  end
end
