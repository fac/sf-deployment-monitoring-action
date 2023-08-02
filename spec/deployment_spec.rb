# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployment::Deployment do
  subject(:deployment) { Deployment::Deployment.new(mock_client, execution_arn) }

  let(:mock_client) { double('Aws::States::Client') }
  let(:execution_arn) { 'arn:aws:states:eu-west-1:123456789012:execution:my-execution-flow' }
  let(:get_exec_history) { [] }

  before(:each) do
    allow(Aws::States::Client).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive(:describe_execution).with(any_args).and_return(desc_exec_resp)
    allow(mock_client).to receive(:get_execution_history).with(any_args).and_return(get_exec_history)
  end

  context 'when deploy is running' do
    let(:desc_exec_resp) { Aws::States::Types::DescribeExecutionOutput.new(status: 'RUNNING') }

    describe 'status' do
      it 'returns RUNNING' do
        expect(deployment.status).to eq('RUNNING')
      end
    end

    describe 'running?' do
      it 'returns true' do
        expect(deployment.running?).to be true
      end
    end

    describe 'failure_reason' do
      it 'should raise an exception' do
        expect { deployment.failure_reason }.to raise_error(RuntimeError)
      end
    end
  end

  context 'when deploy succeeded' do
    let(:desc_exec_resp) { Aws::States::Types::DescribeExecutionOutput.new(status: 'SUCCEEDED') }

    describe 'status' do
      it 'returns SUCCEEDED' do
        expect(deployment.status).to eq('SUCCEEDED')
      end
    end

    describe 'succeeded?' do
      it 'returns true' do
        expect(deployment.succeeded?).to be true
      end
    end

    describe 'running?' do
      it 'returns false' do
        expect(deployment.running?).to be false
      end
    end

    describe 'failure_reason' do
      it 'should raise an exception' do
        expect { deployment.failure_reason }.to raise_error(RuntimeError)
      end
    end
  end

  context 'when deploy failed' do
    let(:desc_exec_resp) { Aws::States::Types::DescribeExecutionOutput.new(status: 'FAILED') }

    describe 'status' do
      it 'returns FAILED' do
        expect(deployment.status).to eq('FAILED')
      end
    end

    describe 'failed?' do
      it 'returns true' do
        expect(deployment.failed?).to be true
      end
    end

    describe 'running?' do
      it 'returns false' do
        expect(deployment.running?).to be false
      end
    end
  end

  context 'when deploy has been aborted' do
    let(:desc_exec_resp) { Aws::States::Types::DescribeExecutionOutput.new(status: 'ABORTED') }

    describe 'status' do
      it 'returns ABORTED' do
        expect(deployment.status).to eq('ABORTED')
      end
    end

    describe 'aborted?' do
      it 'returns true' do
        expect(deployment.aborted?).to be true
      end
    end

    describe 'running?' do
      it 'returns false' do
        expect(deployment.running?).to be false
      end
    end
  end

  context 'when deploy has timed out' do
    let(:desc_exec_resp) { Aws::States::Types::DescribeExecutionOutput.new(status: 'TIMED_OUT') }

    describe 'status' do
      it 'returns TIMED_OUT' do
        expect(deployment.status).to eq('TIMED_OUT')
      end
    end

    describe 'timed_out?' do
      it 'returns true' do
        expect(deployment.timed_out?).to be true
      end
    end

    describe 'running?' do
      it 'returns false' do
        expect(deployment.running?).to be false
      end
    end
  end

  context 'when deploy has failed' do
    let(:desc_exec_resp) { Aws::States::Types::DescribeExecutionOutput.new(status: 'FAILED') }

    describe 'status' do
      it 'returns FAILED' do
        expect(deployment.status).to eq('FAILED')
      end
    end

    describe 'failed?' do
      it 'returns true' do
        expect(deployment.failed?).to be true
      end
    end

    describe 'running?' do
      it 'returns false' do
        expect(deployment.running?).to be false
      end
    end

    context 'when due to LambdaFunctionFailed event' do
      let(:get_exec_history) do
        Aws::States::Types::GetExecutionHistoryOutput.new(
          events: [
            '',
            Aws::States::Types::HistoryEvent.new(type: 'LambdaFunctionFailed')
          ]
        )
      end

      describe 'failure_reason' do
        it 'calls LambdaFunctionFailedError.new(fail_event).error' do
          expect_any_instance_of(Deployment::Events::LambdaFunctionFailed).to receive(:error)
          subject.failure_reason
        end
      end
    end

    context 'when due to FailStateEntered event' do
      let(:get_exec_history) do
        Aws::States::Types::GetExecutionHistoryOutput.new(
          events: [
            '',
            Aws::States::Types::HistoryEvent.new(type: 'FailStateEntered')
          ]
        )
      end

      describe 'failure_reason' do
        it 'calls FailStateEntered.new(fail_event).error' do
          expect_any_instance_of(Deployment::Events::FailStateEntered).to receive(:error)
          subject.failure_reason
        end
      end
    end

    context 'when due to and unknown event' do
      let(:get_exec_history) do
        Aws::States::Types::GetExecutionHistoryOutput.new(
          events: [
            '',
            Aws::States::Types::HistoryEvent.new(type: 'UnknownError')
          ]
        )
      end

      describe 'failure_reason' do
        it 'returns a generic error message' do
          expect(subject.failure_reason).to start_with('Uncaught failure.')
        end
      end
    end
  end
end
