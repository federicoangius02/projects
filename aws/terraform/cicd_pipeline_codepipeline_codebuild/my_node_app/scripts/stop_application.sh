#!/bin/bash
# Stop the Node.js application
systemctl stop node-app || true
pkill -f "node index.js" || true