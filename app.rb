# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('.', 'lib')

require 'aws-sdk-states'
require 'json'

require 'deployment'

STDOUT.sync = true

execution_arn = ENV['EXECUTION_ARN']

if execution_arn.nil?
  puts 'EXECUTION_ARN is required. Please set it as an ENV Variable.'
  exit 1
end

aws_client = Aws::States::Client.new(region: 'eu-west-1')

deploy = Deployment::Deployment.new(aws_client, execution_arn)

if deploy.running?
  puts 'Deployment in progress...🔄'
  puts "Monitor at https://eu-west-1.console.aws.amazon.com/states/home?region=eu-west-1#/executions/details/#{execution_arn}"
end

sleep 10 while deploy.running?

if deploy.succeeded?
  puts 'Deployment Successful 🎉'
else
  puts "Deployment Failure Status: #{deploy.status} ❌"
  File.open(ENV['GITHUB_OUTPUT'], 'a') do |f|
    f.puts 'deployment_failed=true'
    f.puts "deployment_failure_reason=#{deploy.failure_reason}"
  end
end
