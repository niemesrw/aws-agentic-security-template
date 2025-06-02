import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as path from 'path';

/**
 * AgenticSecurityStack deploys a Go-based Lambda function with dynamic prompt loading from S3.
 */
export class AgenticSecurityStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // S3 bucket for storing prompts with versioning enabled
    const promptsBucket = new s3.Bucket(this, 'PromptsBucket', {
      bucketName: `agentic-security-prompts-${this.account}-${this.region}`,
      versioned: true,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      encryption: s3.BucketEncryption.S3_MANAGED,
    });

    // Deploy prompts to S3 automatically
    new s3deploy.BucketDeployment(this, 'DeployPrompts', {
      sources: [s3deploy.Source.asset(path.join(__dirname, '../../prompts'))],
      destinationBucket: promptsBucket,
      destinationKeyPrefix: 'prompts/',
      prune: true, // Remove old files when new ones are deployed
    });

    const agentFunction = new lambda.Function(this, 'AgenticGoHandler', {
      runtime: lambda.Runtime.PROVIDED_AL2023,
      handler: 'bootstrap',
      code: lambda.Code.fromAsset(
        path.join(__dirname, '../../lambda/dist')
      ),
      memorySize: 256,
      timeout: cdk.Duration.seconds(30),
      description: 'Agentic security Lambda with dynamic prompt loading',
      environment: {
        PROMPTS_BUCKET: promptsBucket.bucketName,
        PROMPT_KEY: 'prompts/aws_lambda_security_analysis.prompt.yml',
      },
    });

    // Grant Lambda permission to read from S3 prompts bucket
    promptsBucket.grantRead(agentFunction);

    // Output the Lambda function ARN and S3 bucket for reference
    new cdk.CfnOutput(this, 'AgentFunctionArn', {
      value: agentFunction.functionArn,
      description: 'ARN of the Agentic Security Lambda function',
    });

    new cdk.CfnOutput(this, 'PromptsBucketName', {
      value: promptsBucket.bucketName,
      description: 'S3 bucket containing prompts',
    });

    // Add more constructs/resources as needed
  }
}
