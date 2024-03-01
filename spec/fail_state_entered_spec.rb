# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployment::Events::FailStateEntered do
  subject(:deployment) { Deployment::Events::FailStateEntered.new(event, execution_arn) }

  let(:execution_arn) { 'arn:aws:states:eu-west-1:123456789012:execution:my-execution-flow' }

  context 'when Sidekiq has failed to start' do
    let(:event) do
      Aws::States::Types::HistoryEvent.new(
        type: 'FailStateEntered',
        state_entered_event_details: Aws::States::Types::StateEnteredEventDetails.new(
          input: '
                {
                  "Error": {
                    "Cause":"{\"errorMessage\":\"ECS deployment status: IN_PROGRESS\",\"errorType\":\"Function<DeployInProgress>\",\"stackTrace\":[\"/var/task/ecs_deployment_handler.rb:49:in `handler\"]}",
                    "error":"Function<DeployInProgress>",
                    "resource":"invoke",
                    "resourceType":"lambda"
                  }
                }
              '
        )
      )
    end

    describe(:error) do
      it 'returns the correct error message' do
        expect(deployment.error).to eq('Sidekiq workers failed to start or failed to stabilise.')
      end
    end
  end

  context 'when there is some other failure' do
    let(:event) do
      Aws::States::Types::HistoryEvent.new(
        type: 'FailStateEntered',
        state_entered_event_details: Aws::States::Types::StateEnteredEventDetails.new(
          input: '
                {
                  "Error": {
                    "Cause":"{\"errorMessage\":\"Some other error\"}",
                    "error":"Function<DeployInProgress>",
                    "resource":"invoke",
                    "resourceType":"lambda"
                  }
                }
              '
        )
      )
    end

    describe(:error) do
      it 'returns the error message' do
        expect(deployment.error).to start_with('Failure message: Some other error')
      end
    end
  end
end
