#!/bin/bash
set -e

echo "Restarting deployment to pull latest image..."
kubectl rollout restart deployment/nbucking-web -n default

echo "Waiting for rollout to complete..."
kubectl rollout status deployment/nbucking-web -n default --timeout=120s

echo "Deployment successful! Current pods:"
kubectl get pods -n default -l app=nbucking-web
