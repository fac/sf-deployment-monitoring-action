require 'aws-sdk-states'
require 'json'

STDOUT.sync = true

execution_arn = ENV['EXECUTION_ARN']

if execution_arn.nil?
  puts 'EXECUTION_ARN is required. Please set it as an ENV Variable.'
  exit 1
end

aws_client = Aws::States::Client.new(region: 'eu-west-1')

def deployment_status(aws_client, execution_arn)
  aws_client.describe_execution({ execution_arn: execution_arn }).status
end

def failure_reason(aws_client, execution_arn)
  resp = aws_client.get_execution_history({
    execution_arn: execution_arn,
    max_results: 2,
    reverse_order: true
  })

  event_type = resp.events[1].type
  if event_type == "LambdaFunctionFailed"
    error_message = JSON.parse(resp.events[1].lambda_function_failed_event_details.cause)['errorMessage']
    if error_message.include? "Pre flight checks failed"
      preflight_checks_output = error_message.lines[1]
      forward_deploy_check_result =  preflight_checks_output.match(/ForwardDeployCheck=>"(.*)",/i).captures[0]
      if forward_deploy_check_result == "FAILED"
        deploy_fail_reason = "Forward deploy check FAILED. No need to panic! "\
                             "This likely means your commit has already been deployed as part of a previous deploy. "\
                             "To confirm you can check whether your SHA is a parent commit to the currently deployed SHA. "\
                             "You can figure out the currently deployed SHA by following this guide https://www.notion.so/freeagent/Deployment-Runbooks-29796221387e40b7abbb217d7d33c4ac?pvs=4#3bfa2ab5d3ab4c33b7a46522027f94bb"
        return deploy_fail_reason
      end
    end
    deploy_fail_reason = error_message
  elsif event_type == "FailStateEntered"
    error_message = JSON.parse(JSON.parse(resp.events[1].state_entered_event_details.input)['Error']['Cause'])['errorMessage']
    if error_message.include? "ECS" and error_message.include? "IN_PROGRESS"
      deploy_fail_reason = "Sidekiq workers failed to start or failed to stabilise."
    else
      deploy_fail_reason = "Failure message: #{error_message}. Please investigate further here if required https://eu-west-1.console.aws.amazon.com/states/home?region=eu-west-1#/executions/details/#{execution_arn}"
    end
  else
    deploy_fail_reason = "Uncaught failure. Please investigate here https://eu-west-1.console.aws.amazon.com/states/home?region=eu-west-1#/executions/details/#{execution_arn}"
  end

  return deploy_fail_reason
end

# One of: "RUNNING", "SUCCEEDED", "FAILED", "TIMED_OUT", "ABORTED"
if deployment_status(aws_client, execution_arn) == 'RUNNING'
  puts 'Deployment in progress...🔄'
  puts "Monitor at https://eu-west-1.console.aws.amazon.com/states/home?region=eu-west-1#/executions/details/#{execution_arn}"
  sleep 15 until deployment_status(aws_client, execution_arn) != 'RUNNING'
end

deploy_status = deployment_status(aws_client, execution_arn)
if %w[FAILED TIMED_OUT ABORTED].include?(deploy_status)
  puts "Deployment Failure Status: #{deploy_status} ❌"
  File.open(ENV['GITHUB_OUTPUT'], 'a') do |f|
    f.puts "deployment_failed=true"
    f.puts "deployment_failure_reason=#{failure_reason(aws_client, execution_arn)}"
  end
elsif deploy_status == 'SUCCEEDED'
  puts 'Deployment Successful 🎉'
end
