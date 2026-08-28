#!/bin/bash
# Opens an SSM port forwarding session to access the wg-easy panel locally.
# Usage: bash scripts/tunnel.sh <INSTANCE_ID> [AWS_REGION]
#
# Requires: AWS CLI + Session Manager plugin
# Install plugin: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
#
# After running, open http://localhost:51821 in your browser.

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <INSTANCE_ID> [AWS_REGION]"
  echo "  INSTANCE_ID: EC2 instance ID (from terraform output instance_id)"
  echo "  AWS_REGION:  defaults to us-east-1"
  exit 1
fi

INSTANCE_ID="$1"
REGION="${2:-us-east-1}"

echo "Opening SSM tunnel to wg-easy panel..."
echo "Access the panel at: http://localhost:51821"
echo "Press Ctrl+C to close."
echo ""

aws ssm start-session \
  --target "$INSTANCE_ID" \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["51821"],"localPortNumber":["51821"]}' \
  --region "$REGION"
