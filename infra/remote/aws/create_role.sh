#!/bin/bash
set -e

ROLE_NAME="terraform-role"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Creating IAM role: $ROLE_NAME"

# Create trust policy
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${ACCOUNT_ID}:user/main"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create role
aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document file://trust-policy.json

# Attach policies
POLICIES=(
  "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
)

for POLICY in "${POLICIES[@]}"; do
  echo "Attaching policy: $POLICY"
  aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "$POLICY"
done

# Cleanup
rm trust-policy.json

echo ""
echo "Terraform role created successfully!"
echo ""
echo "Role ARN:"
echo "arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

echo "IMPORTANT"
echo "update postgres/provider.tf role_arn with the current:"
echo "arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
