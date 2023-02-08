# Step Function Deployment Monitoring

## Description

GitHub Action used to monitor AWS StepFunction deployments.

## Usage

```yaml
   - name: Monitor Deploy
     id: monitor
     uses: fac/sf-deployment-monitoring-action@v1
     with:
       EXECUTION_ARN: ""
```

## Inputs

### EXECUTION_ARN

The StepFunction execution arn that you wish to track the status of.


## Development

Install locally with 

```bash
bundle install
```

Then, if you have an AWS StepFunction execution ARN you can test the logic as follows:

```bash
export EXECUTION_ARN=arn:aws:states:eu-west-1:123456789012:execution:example-state-machine:12345678-9012-3456-7890-123456789012
ruby app.rb # Remember to take care of authentication with AWS. For example, if you are using vault, then you could execute `aws-vault exec myprofile -- ruby app.rb
```

## Authors

* FreeAgent Ops opensource@freeagent.com
## Licence

```
Copyright 2022 FreeAgent Central Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
