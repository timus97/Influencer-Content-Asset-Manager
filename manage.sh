#!/bin/bash

# Script to start/stop backend and frontend
# Usage: ./manage.sh start|stop

BACKEND_DIR="/testbed/InfluencerContentAssetManager"
FRONTEND_DIR="/testbed/frontend"
PID_FILE="/tmp/icam_pids.txt"

# Function to find a free port starting from given port
find_free_port() {
    local port=$1
    while lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; do
        port=$((port + 1))
    done
    echo $port
}

# Function to start backend
start_backend() {
    cd "$BACKEND_DIR"
    BACKEND_PORT=$(find_free_port 8080)
    echo "Starting backend on port $BACKEND_PORT"
    export SERVER_PORT=$BACKEND_PORT
    mvn spring-boot:run > backend.log 2>&1 &
    BACKEND_PID=$!
    echo "backend $BACKEND_PID $BACKEND_PORT" >> "$PID_FILE"
}

# Function to start frontend
start_frontend() {
    cd "$FRONTEND_DIR"
    FRONTEND_PORT=$(find_free_port 3000)
    echo "Starting frontend on port $FRONTEND_PORT"
    export PORT=$FRONTEND_PORT
    npm start > frontend.log 2>&1 &
    FRONTEND_PID=$!
    echo "frontend $FRONTEND_PID $FRONTEND_PORT" >> "$PID_FILE"
}

# Function to stop all
stop_all() {
    if [ -f "$PID_FILE" ]; then
        while IFS= read -r line; do
            SERVICE=$(echo $line | cut -d' ' -f1)
            PID=$(echo $line | cut -d' ' -f2)
            PORT=$(echo $line | cut -d' ' -f3)
            if kill -0 $PID 2>/dev/null; then
                echo "Stopping $SERVICE (PID: $PID) on port $PORT"
                kill $PID
                sleep 2
                if kill -0 $PID 2>/dev/null; then
                    kill -9 $PID
                fi
            fi
        done < "$PID_FILE"
        rm -f "$PID_FILE"
    else
        echo "No PID file found. Nothing to stop."
    fi
}

case "$1" in
    start)
        echo "Starting ICAM application..."
        rm -f "$PID_FILE"
        start_backend
        sleep 5  # Wait for backend to start
        start_frontend
        echo "Application started. Check logs for details."
        ;;
    stop)
        echo "Stopping ICAM application..."
        stop_all
        echo "Application stopped."
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac