package main

import (
    "context"
    "flag"
    "google.golang.org/grpc"
    "google.golang.org/grpc/codes"
    "google.golang.org/grpc/health"
    "google.golang.org/grpc/health/grpc_health_v1"
    "google.golang.org/grpc/reflection"
    "google.golang.org/genproto/googleapis/rpc/status"
    "log"
    "net"
    "os"
    "os/signal"
    "syscall"
    ext_authz "github.com/envoyproxy/go-control-plane/envoy/service/auth/v3"
)

const (
    // unix socket
    PROTOCOL = "unix"
    // SOCKET = "/var/run/grpchello.sock"

    // tcp protocol
    PROTOCOL_TCP = "tcp"
    ADDR         = "0.0.0.0:17772"
    // certFile   = "server.crt"
    // keyFile    = "server.key"    
)

type authServer struct{}

type loggingListener struct {
	net.Listener
}

func (ln *loggingListener) Accept() (net.Conn, error) {
	conn, err := ln.Listener.Accept()
	if err != nil {
		return nil, err
	}
	log.Printf("Accepted connection from: %v", conn.RemoteAddr())
	return conn, nil
}

func (s *authServer) Check(ctx context.Context, req *ext_authz.CheckRequest) (*ext_authz.CheckResponse, error) {
    log.Printf("Received authorization request: %v", req)
    // Perform authorization check and create a response
    res := &ext_authz.CheckResponse{
        Status: &status.Status{
            Code:    int32(codes.OK),
            Message: "OK",
        },
    }
    return res, nil
}

func main() {
    // load server certificate and key
    // cert, err := tls.LoadX509KeyPair(certFile, keyFile)
    // if err != nil {
    //     log.Fatalf("failed to load server certificate and key: %v", err)
    // }

    // create TLS config
    // tlsConfig := &tls.Config{
    //     Certificates: []tls.Certificate{cert},
    // }

    // create gRPC server using TLS config
    // SOCKET := flag.String("socket", "/var/run/grpchello.sock", "Unix socket path")
    flag.Parse()
    // ln, err := net.Listen(PROTOCOL, *SOCKET)
    // if err != nil {
    //     log.Fatal(err)
    // }

    tcpLn, err := net.Listen(PROTOCOL_TCP, ADDR)
    if err != nil {
        log.Fatal(err)
    }

    // srv := grpc.NewServer(grpc.Creds(credentials.NewTLS(tlsConfig)))
    srv := grpc.NewServer()
    grpc_health_v1.RegisterHealthServer(srv, health.NewServer())
    reflection.Register(srv)
    ext_authz.RegisterAuthorizationServer(srv, &authServer{})

    stop := make(chan os.Signal, 1)
    signal.Notify(stop, syscall.SIGTERM, syscall.SIGINT)
    go func() {
        log.Printf("grpc ran on tcp protocol %s", ADDR)
        if err := srv.Serve(&loggingListener{tcpLn}); err != nil { 
            log.Fatal("failed to server on tcp %v", err)
        }
    }()
    // go func() {
    //     log.Printf("grpc ran on unix socket protocol %s", *SOCKET)
    //     if err := srv.Serve(ln); err != nil { 
    //         log.Fatal("failed to server on socket %v", err)
    //     }
    // }()
    <-stop
    log.Println("stopping gRPC server")
    srv.GracefulStop()
}
