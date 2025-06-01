import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as path from 'path';

/**
 * AgenticSecurityStack deploys a Go-based Lambda function as an example.
 */
export class AgenticSecurityStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const agentFunction = new lambda.Function(this, 'AgenticGoHandler', {
      runtime: lambda.Runtime.GO_1_X,
      handler: 'main',
      code: lambda.Code.fromAsset(
        path.join(__dirname, '../../lambda/dist')
      ),
      memorySize: 128,
      timeout: cdk.Duration.seconds(10),
      description: 'Agentic security Lambda written in Go',
    });

    // Add more constructs/resources as needed
  }
}