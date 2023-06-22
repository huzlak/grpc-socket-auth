#!/bin/bash
kubectl apply -f- <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grpc-socket-hello-deploy
  labels:
    app: grpc-socket-hello-deploy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grpc-socket-hello-deploy
  template:
    metadata:
      labels:
        app: grpc-socket-hello-deploy
    spec:
      containers:
      - name: grpc-socket-hello
        image: "ghcr.io/huzlak/grpc-socket-hello:v8"
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 17772
          name: grpc
        resources:
          requests:
            memory: 16Mi
            cpu: 100m
          limits:
            memory: 32Mi
            cpu: 250m
---
apiVersion: v1
kind: Service
metadata:
  name: grpc-socket-hello-deploy
  labels:
    app: grpc-socket-hello-deploy
spec:
  ports:
  - port: 17772
    targetPort: "grpc"
    protocol: TCP
    name: grpc
  selector:
    app: grpc-socket-hello-deploy
  type: LoadBalancer
EOF
