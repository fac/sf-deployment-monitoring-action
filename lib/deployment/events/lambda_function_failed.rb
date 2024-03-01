module Deployment
  module Events
    class LambdaFunctionFailed
      def initialize(event)
        @event = event
      end

      def error
        if preflight_checks_failed? && forward_deploy_check_failed?
          'Forward deploy check FAILED. No need to panic! '\
          'This likely means your commit has already been deployed as part of a previous deploy. '\
          'To confirm you can check whether your SHA is a parent commit to the currently deployed SHA. '\
          'You can figure out the currently deployed SHA by following this guide https://www.notion.so/freeagent/Deployment-Runbooks-29796221387e40b7abbb217d7d33c4ac?pvs=4#3bfa2ab5d3ab4c33b7a46522027f94bb'
        else
          error_message
        end
      end

      private

      def error_message
        @error_message ||= JSON.parse(@event.lambda_function_failed_event_details.cause)['errorMessage']
      end

      def preflight_checks_output
        error_message.lines[1]
      end

      def preflight_checks_failed?
        error_message.include? 'Pre flight checks failed'
      end

      def forward_deploy_check_result
        preflight_checks_output.match(/ForwardDeployCheck=>"(.*?)"/i).captures[0]
      end

      def forward_deploy_check_failed?
        forward_deploy_check_result == 'FAILED'
      end
    end
  end
end
