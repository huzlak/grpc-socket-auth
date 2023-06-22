#!/bin/bash
kubectl apply -f- <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: grpc-socket-hello
  namespace: default
  labels:
    app: grpc-socket-hello
spec:
  selector:
    matchLabels:
      app: grpc-socket-hello
  template:
    metadata:
      labels:
        app: grpc-socket-hello
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values:
                - kind8-worker
      containers:
      - name: grpc-socket-hello
        securityContext:
          privileged: true
        image: ghcr.io/huzlak/grpc-socket-hello:v8
        imagePullPolicy: IfNotPresent
        args:
        - "/grpcsocket"
        - "-socket=/var/run/sockets/grpc-socket-hello.sock"
        ports:
        - containerPort: 17772
          name: grpc
        resources:
          limits:
            cpu: 100m
            memory: 128Mi
          requests:
            cpu: 100m
            memory: 128Mi
        volumeMounts:
        - name: socket-dir
          mountPath: /var/run/sockets/
      volumes:
      - name: socket-dir
        hostPath:
          path: /tmp/socket/
          type: DirectoryOrCreate
---
apiVersion: v1
kind: Service
metadata:
  name: grpc-socket-hello
  labels:
    app: grpc-socket-hello
spec:
  ports:
  - port: 17772
    targetPort: "grpc"
    protocol: TCP
    name: grpc
  selector:
    app: grpc-socket-hello
  type: LoadBalancer
EOF
