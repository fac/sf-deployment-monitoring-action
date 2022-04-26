require 'optparse'
require 'aws-sdk-states'

options = {}
option_parser = OptionParser.new do |opts|
  opts.banner = 'Usage: app.rb [options]'
  opts.on('-e', '--execution-arn <arn>', 'Step Function Execution ARN to monitor') do |v|
    options[:execution_arn] = v
  end
end

option_parser.parse!
if options[:execution_arn].nil?
  puts 'StepFunction execution arn is required!'
  puts option_parser.help
  exit 1
end

def get_deployment(execution_arn)
  aws_client = Aws::States::Client.new(region: 'eu-west-1')
  aws_client.describe_execution({ execution_arn: execution_arn })
end

deployment_status = get_deployment(options[:execution_arn]).status

# One of: "RUNNING", "SUCCEEDED", "FAILED", "TIMED_OUT", "ABORTED"
if deployment_status == 'RUNNING'
  puts 'Deployment in progress...🔄'
  sleep 15 until get_deployment(options[:execution_arn]).status != 'RUNNING'
end

if %w[FAILED TIMED_OUT ABORTED].include?(deployment_status)
  puts "Deployment Failed: #{deployment_status} ❌"
  exit 1
elsif deployment_status == 'SUCCEEDED'
  puts 'Deployment Successful 🎉'
  exit 0
end
