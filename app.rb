require 'aws-sdk-states'

if ENV['EXECUTION_ARN'].nil?
  puts 'EXECUTION_ARN is required. Please set it as an ENV Variable.'
  exit 1
end

def deployment_status
  aws_client = Aws::States::Client.new(region: 'eu-west-1')
  aws_client.describe_execution({ execution_arn: ENV['EXECUTION_ARN'] }).status
end

# One of: "RUNNING", "SUCCEEDED", "FAILED", "TIMED_OUT", "ABORTED"
if deployment_status == 'RUNNING'
  puts 'Deployment in progress...🔄'
  sleep 15 until deployment_status != 'RUNNING'
end

if %w[FAILED TIMED_OUT ABORTED].include?(deployment_status)
  puts "Deployment Failure Status: #{deployment_status} ❌"
  exit 1
elsif deployment_status == 'SUCCEEDED'
  puts 'Deployment Successful 🎉'
  exit 0
end
