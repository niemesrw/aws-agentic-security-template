#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { AgenticSecurityStack } from '../lib/agentic-security-stack';
import * as dotenv from 'dotenv';
import * as path from 'path';

// Load environment variables from .env.local if it exists
dotenv.config({ path: path.join(__dirname, '../../.env.local') });

// CDK app entrypoint
const app = new cdk.App();
new AgenticSecurityStack(app, 'AgenticSecurityStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT || process.env.AWS_ACCOUNT_ID,
    region: process.env.CDK_DEFAULT_REGION || process.env.AWS_DEFAULT_REGION || 'us-east-1',
  },
});