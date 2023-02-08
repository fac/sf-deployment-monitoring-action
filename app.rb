require 'aws-sdk-states'
require 'json'

STDOUT.sync = true

if ENV['EXECUTION_ARN'].nil?
  puts 'EXECUTION_ARN is required. Please set it as an ENV Variable.'
  exit 1
end

aws_client = Aws::States::Client.new(region: 'eu-west-1')

def deployment_status(aws_client)
  aws_client.describe_execution({ execution_arn: ENV['EXECUTION_ARN'] }).status
end

def failure_reason(aws_client)
  resp = aws_client.get_execution_history({
    execution_arn: ENV['EXECUTION_ARN'],
    max_results: 2,
    reverse_order: true
  })
  error_message = JSON.parse(JSON.parse(resp.events[1].state_entered_event_details.input)['Error']['Cause'])['errorMessage']

  if error_message.include? "ECS" and error_message.include? "IN_PROGRESS"
    deploy_fail_reason = "Sidekiq workers failed to start or failed to stabilise."
  else
    deploy_fail_reason = "Unknown. Please investigate here https://eu-west-1.console.aws.amazon.com/states/home?region=eu-west-1#/executions/details/#{ENV['EXECUTION_ARN']}"
  end

  return deploy_fail_reason
end

# One of: "RUNNING", "SUCCEEDED", "FAILED", "TIMED_OUT", "ABORTED"
if deployment_status(aws_client) == 'RUNNING'
  puts 'Deployment in progress...🔄'
  puts "Monitor at https://eu-west-1.console.aws.amazon.com/states/home?region=eu-west-1#/executions/details/#{ENV['EXECUTION_ARN']}"
  sleep 15 until deployment_status(aws_client) != 'RUNNING'
end

deploy_status = deployment_status(aws_client)
if %w[FAILED TIMED_OUT ABORTED].include?(deploy_status)
  puts "Deployment Failure Status: #{deploy_status} ❌"
  File.open(ENV['GITHUB_OUTPUT'], 'a') do |f|
    f.puts "deployment_failed=true"
    f.puts "deployment_failure_reason=#{failure_reason(aws_client)}"
  end
elsif deploy_status == 'SUCCEEDED'
  puts 'Deployment Successful 🎉'
end
