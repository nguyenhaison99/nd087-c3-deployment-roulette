#!/bin/bash

# Function to manually verify the environment
function manual_verification {
  read -p "Use the following command to verify: k run debug --rm -i --tty --image nicolaka/netshoot -- /bin/bash" answer

  if [[ $answer =~ ^[Yy]$ ]] ;
  then
      echo "Continuing deployment..."
  else
      echo "Exiting script."
      exit
  fi
}

# Function for Canary Deployment
function canary_deploy {
  # Count the number of V1 pods
  NUM_OF_V1_PODS=$(kubectl get pods -n udacity | grep -c canary-v1)
  echo "V1 PODS: $NUM_OF_V1_PODS"

  # Set the target number of V2 pods to match V1 pods
  TARGET_V2_PODS=$NUM_OF_V1_PODS
  echo "Number of V2 PODS will be deployed: $TARGET_V2_PODS"
  kubectl scale deployment canary-v2 --replicas=$TARGET_V2_PODS

  # Check deployment rollout status every 1 second until complete.
  ATTEMPTS=0
  ROLLOUT_STATUS_CMD="kubectl rollout status deployment/canary-v2 -n udacity"
  until $ROLLOUT_STATUS_CMD || [ $ATTEMPTS -eq 60 ]; do
      $ROLLOUT_STATUS_CMD
      ATTEMPTS=$((ATTEMPTS + 1))
      sleep 1
  done

  # Count the number of V1 and V2 pods again for verification
  NUM_OF_V1_PODS=$(kubectl get pods -n udacity | grep -c canary-v1)
  echo "V1 PODS: $NUM_OF_V1_PODS"
  NUM_OF_V2_PODS=$(kubectl get pods -n udacity | grep -c canary-v2)
  echo "V2 PODS: $NUM_OF_V2_PODS"
  echo "Canary deployment of $TARGET_V2_PODS replicas successful!"
}

# Logging to a file canary.log
LOG_FILE="canary.log"
exec > >(tee -i $LOG_FILE)
exec 2>&1

echo "Starting canary deployment..."

# Apply the canary-v2.yml configuration
kubectl apply -f canary-v2.yml

# Manual verification step
echo "Verification check. Use the following command to verify: kubectl run debug --rm -i --tty --image nicolaka/netshoot -- /bin/bash"
manual_verification

# Perform the Canary Deployment
canary_deploy

