module Deployment
  module Events
    class FailStateEntered
      def initialize(event, execution_arn)
        @event = event
        @execution_arn = execution_arn
      end

      def error
        if sidekiq_error?
          'Sidekiq workers failed to start or failed to stabilise.'
        else
          "Failure message: #{error_message}. Please investigate further here if required https://eu-west-1.console.aws.amazon.com/states/home?region=eu-west-1#/executions/details/#{@execution_arn}"
        end
      end

      private

      def error_message
        @error_message ||= JSON.parse(JSON.parse(@event.state_entered_event_details.input)['Error']['Cause'])['errorMessage']
      end

      def in_progress?
        error_message.include? 'IN_PROGRESS'
      end

      def ecs_error?
        error_message.include? 'ECS'
      end

      def sidekiq_error?
        ecs_error? && in_progress?
      end
    end
  end
end
