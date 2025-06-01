#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { AgenticSecurityStack } from '../lib/agentic-security-stack';

// CDK app entrypoint
const app = new cdk.App();
new AgenticSecurityStack(app, 'AgenticSecurityStack');