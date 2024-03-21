# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployment::Events::LambdaFunctionFailed do
  subject(:deployment) { Deployment::Events::LambdaFunctionFailed.new(event) }

  context 'one pre flight check failed' do
    let(:event) do
      Aws::States::Types::HistoryEvent.new(
        type: 'LambdaFunctionFailed',
        lambda_function_failed_event_details: Aws::States::Types::LambdaFunctionFailedEventDetails.new(
          cause: '
            {
              "errorMessage": "Pre flight checks failed:\n{\"Checks\"=>{:RequiredParameters=>\"PASSED\", :CommitCheck=>\"PASSED\", :ScheduleCheck=>\"PASSED\", :ForwardDeployCheck=>\"FAILED\"}, \"Status\"=>\"FAILED\"}",
              "errorType": "Function<StandardError>",
              "stackTrace": [
                "/var/task/pre_flight_checks.rb:145:in `handler"
              ]
            }'
        )
      )
    end

    describe(:error) do
      it 'returns the correct error message' do
        expect(deployment.error).to start_with('The following pre-flight checks have failed: ForwardDeployCheck')
      end
    end
  end

  context 'multiple pre flight checks failed' do
    let(:event) do
      Aws::States::Types::HistoryEvent.new(
        type: 'LambdaFunctionFailed',
        lambda_function_failed_event_details: Aws::States::Types::LambdaFunctionFailedEventDetails.new(
          cause: '
            {
              "errorMessage": "Pre flight checks failed:\n{\"Checks\"=>{:RequiredParameters=>\"FAILED\", :CommitCheck=>\"FAILED\", :ScheduleCheck=>\"FAILED\", :ForwardDeployCheck=>\"PASSED\"}, \"Status\"=>\"FAILED\"}",
              "errorType": "Function<StandardError>",
              "stackTrace": [
                "/var/task/pre_flight_checks.rb:145:in `handler"
              ]
            }'
        )
      )
    end

    describe(:error) do
      it 'returns full preflight failure details' do
        expect(deployment.error).to start_with('The following pre-flight checks have failed: CommitCheck, RequiredParameters, ScheduleCheck.')
      end
    end
  end

  context 'some other function failed' do
    let(:event) do
      Aws::States::Types::HistoryEvent.new(
        type: 'LambdaFunctionFailed',
        lambda_function_failed_event_details: Aws::States::Types::LambdaFunctionFailedEventDetails.new(
          cause: '
            {
              "errorMessage": "Some other error",
              "errorType": "Function<StandardError>",
              "stackTrace": [
                "/var/task/another_function.rb:145:in `handler"
              ]
            }'
        )
      )
    end

    describe(:error) do
      it 'returns the error message' do
        expect(deployment.error).to start_with('Some other error')
      end
    end
  end
end
