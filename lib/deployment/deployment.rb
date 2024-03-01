module Deployment
  class Deployment
    def initialize(aws_client, execution_arn)
      @aws_client = aws_client
      @execution_arn = execution_arn
    end

    def status
      @aws_client.describe_execution({ execution_arn: @execution_arn }).status
    end

    def running?
      status == 'RUNNING'
    end

    def succeeded?
      status == 'SUCCEEDED'
    end

    def aborted?
      status == 'ABORTED'
    end

    def timed_out?
      status == 'TIMED_OUT'
    end

    def failed?
      status == 'FAILED'
    end

    def failure_reason
      raise 'Deploy still runnning' if running?
      raise 'Deploy succeeded' if succeeded?

      event_type = fail_event.type

      case event_type
      when 'LambdaFunctionFailed'
        Events::LambdaFunctionFailed.new(fail_event).error
      when 'FailStateEntered'
        Events::FailStateEntered.new(fail_event, @execution_arn).error
      else
        "Uncaught failure. Please investigate here https://eu-west-1.console.aws.amazon.com/states/home?region=eu-west-1#/executions/details/#{@execution_arn}"
      end
    end

    private

    def fail_event
      # The penultimate event holds the failure reason
      @aws_client.get_execution_history(
        {
          execution_arn: @execution_arn,
          max_results: 2,
          reverse_order: true
        }
      ).events.last
    end
  end
end
