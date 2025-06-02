import { App } from 'aws-cdk-lib';
import { AgenticSecurityStack } from '../lib/agentic-security-stack';
import { Template } from 'aws-cdk-lib/assertions';

test('Stack contains a Lambda Function', () => {
  const app = new App();
  const stack = new AgenticSecurityStack(app, 'TestStack');
  const template = Template.fromStack(stack);

  template.hasResourceProperties('AWS::Lambda::Function', {
    Runtime: 'provided.al2023',
    Handler: 'bootstrap',
    Description: 'Agentic security Lambda with dynamic prompt loading'
  });
});