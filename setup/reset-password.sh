#!/bin/sh

# curl -sfL https://get.outpost.run/reset-password.sh | sh -

DEPLOYMENT="outpost"
NAMESPACE="outpost"

# Get the first pod name of the deployment
POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app="$DEPLOYMENT" -o jsonpath="{.items[0].metadata.name}")

if [ -z "$POD_NAME" ]; then
    echo "Could not find a running Outpost instance on your server/cluster."
    exit 1
fi

echo "Found Outpost instance: $POD_NAME"
echo "Initializing password change..."

# Patch the deployment to add or update START_MODE=reset-password
kubectl patch deployment "$DEPLOYMENT" -n "$NAMESPACE" --type='json' -p='[
    {
        "op": "add",
        "path": "/spec/template/spec/containers/0/env/-",
        "value": { "name": "START_MODE", "value": "reset-password" }
    }
]'

echo "Initialized password change successfully, please wait..."

sleep 2

echo "Waiting for the new pod to be in Running status..."
kubectl wait --for=condition=Ready pod -l app="$DEPLOYMENT" -n "$NAMESPACE" --timeout=300s

# Retreive the new pod name
NEW_POD=""
while [ -z "$NEW_POD" ] || [ "$NEW_POD" = "$OLD_POD" ]; do
    sleep 2
    NEW_POD=$(kubectl get pods -n "$NAMESPACE" -l app="$DEPLOYMENT" -o jsonpath="{.items[-1].metadata.name}")
done

kubectl logs -f "$NEW_POD" -n "$NAMESPACE"
