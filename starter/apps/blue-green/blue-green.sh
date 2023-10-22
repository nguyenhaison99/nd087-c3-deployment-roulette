#!/bin/bash

# This script initiates a green deployment using Kubernetes.

# Apply the configuration from green.yml
kubectl apply -f green.yml

# Print a success message
echo "Green deployment successful"