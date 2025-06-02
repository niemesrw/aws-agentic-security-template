import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as path from 'path';

/**
 * AgenticSecurityStack deploys a Go-based Lambda function using the AWS Lambda Provided runtime.
 */
export class AgenticSecurityStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const agentFunction = new lambda.Function(this, 'AgenticGoHandler', {
      runtime: lambda.Runtime.PROVIDED_AL2023,
      handler: 'bootstrap',
      code: lambda.Code.fromAsset(
        path.join(__dirname, '../../lambda/dist')
      ),
      memorySize: 256,
      timeout: cdk.Duration.seconds(30),
      description: 'Agentic security Lambda with dynamic prompt loading',
    });

    // Output the Lambda function ARN for reference
    new cdk.CfnOutput(this, 'AgentFunctionArn', {
      value: agentFunction.functionArn,
      description: 'ARN of the Agentic Security Lambda function',
    });

    // Add more constructs/resources as needed
  }
}