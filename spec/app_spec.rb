require 'rspec'
require 'stringio'

require 'aws-sdk-states'

RSpec.describe 'app' do
  let(:mock_client) { double('Aws::States::Client') }
  let(:execution_arn) { 'arn:aws:states:eu-west-1:123456789012:execution:my-execution-flow' }
  let(:test_github_log) { Tempfile.new('github_output') }

  before(:each) do
    ENV['EXECUTION_ARN'] = execution_arn
    ENV['GITHUB_OUTPUT'] = test_github_log.path
    allow(Aws::States::Client).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive(:describe_execution).with(any_args).and_return(desc_exec_resp)
    allow(mock_client).to receive(:get_execution_history).with(any_args).and_return(get_exec_history)
  end

  context 'when deployment was successful' do
    let(:desc_exec_resp) { Aws::States::Types::DescribeExecutionOutput.new(status: 'SUCCEEDED') }
    let(:get_exec_history) {}

    it 'outputs "Deployment Successful 🎉"' do
      $stdout = StringIO.new

      # Execute the script
      load "#{__dir__}/../app.rb"

      # Assert the output
      expect($stdout.string).to eq("Deployment Successful 🎉\n")
    end
  end

  context 'when forward deploy check failed' do
    let(:desc_exec_resp) { Aws::States::Types::DescribeExecutionOutput.new(status: 'FAILED') }
    let(:get_exec_history) do
      Aws::States::Types::GetExecutionHistoryOutput.new(
        events: [
          '',
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
        ]
      )
    end

    it 'outputs that it failed' do
      $stdout = StringIO.new

      # Execute the script
      load "#{__dir__}/../app.rb"

      # Assert the output
      expect($stdout.string).to eq("Deployment Failure Status: FAILED ❌\n")
      expect(File.readlines(test_github_log.path)).to eq(
        [
          "deployment_failed=true\n",
          'deployment_failure_reason=' \
            'Forward deploy check FAILED. No need to panic! '\
            'This likely means your commit has already been deployed as part of a previous deploy. '\
            'To confirm you can check whether your SHA is a parent commit to the currently deployed SHA. '\
            "You can figure out the currently deployed SHA by following this guide https://www.notion.so/freeagent/Deployment-Runbooks-29796221387e40b7abbb217d7d33c4ac?pvs=4#3bfa2ab5d3ab4c33b7a46522027f94bb\n"
        ]
      )
    end
  end

  context 'when sidekiq failed to start' do
    let(:desc_exec_resp) { Aws::States::Types::DescribeExecutionOutput.new(status: 'FAILED') }
    let(:get_exec_history) do
      Aws::States::Types::GetExecutionHistoryOutput.new(
        events: [
          '',
          Aws::States::Types::HistoryEvent.new(
            type: 'FailStateEntered',
            state_entered_event_details: Aws::States::Types::StateEnteredEventDetails.new(
              input: '
                {
                  "Error": {
                    "Cause":"{\"errorMessage\":\"ECS deployment status: IN_PROGRESS\",\"errorType\":\"Function<DeployInProgress>\",\"stackTrace\":[\"/var/task/ecs_deployment_handler.rb:49:in `handler\"]}",
                    "error":"Function<DeployInProgress>","resource":"invoke","resourceType":"lambda}"
                  }
                }
              '
            )
          )
        ]
      )
    end

    it 'outputs that it failed' do
      $stdout = StringIO.new

      # Execute the script
      load "#{__dir__}/../app.rb"

      # Assert the output
      expect($stdout.string).to eq("Deployment Failure Status: FAILED ❌\n")
      expect(File.readlines(test_github_log.path)).to eq(
        [
          "deployment_failed=true\n",
          "deployment_failure_reason=Sidekiq workers failed to start or failed to stabilise.\n"
        ]
      )
    end
  end
end
