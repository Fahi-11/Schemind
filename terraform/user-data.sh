#!/bin/bash

# User data script for EC2 instance
# This script installs Docker and runs the Schemind application

# Update system
yum update -y

# Install Docker
yum install -y docker
service docker start
usermod -a -G docker ec2-user

# Install Docker Compose (optional)
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create application directory
mkdir -p /opt/schemind
cd /opt/schemind

# Create docker-compose.yml for the application
cat > docker-compose.yml << EOF
version: '3.8'

services:
  schemind:
    image: ${docker_image}
    container_name: schemind-app
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - PORT=3000
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "node", "-e", "require('http').get('http://localhost:3000', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
EOF

# Pull and start the Docker image
docker-compose pull
docker-compose up -d

# Wait for application to start
echo "Waiting for application to start..."
sleep 30

# Check if application is running
for i in {1..10}; do
    if curl -f http://localhost:3000 > /dev/null 2>&1; then
        echo "✅ Application is running successfully!"
        break
    else
        echo "Waiting for application to start... (Attempt $i/10)"
        sleep 10
    fi
done

# Setup log rotation for Docker logs
cat > /etc/logrotate.d/docker-containers << EOF
/var/lib/docker/containers/*/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
EOF

# Create a simple status script
cat > /usr/local/bin/check-schemind.sh << 'EOF'
#!/bin/bash
echo "=== Schemind Application Status ==="
echo "Container Status:"
docker ps --filter "name=schemind-app" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "Application Health Check:"
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Application is healthy"
else
    echo "❌ Application is not responding"
fi
echo ""
echo "Recent Logs:"
docker logs schemind-app --tail 20
EOF

chmod +x /usr/local/bin/check-schemind.sh

# Create a restart script
cat > /usr/local/bin/restart-schemind.sh << 'EOF'
#!/bin/bash
echo "Restarting Schemind application..."
cd /opt/schemind
docker-compose restart
echo "Application restarted. Check status with: check-schemind.sh"
EOF

chmod +x /usr/local/bin/restart-schemind.sh

echo "=== Setup Complete ==="
echo "Application deployed with image: ${docker_image}"
echo "Application URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
echo "Check status: check-schemind.sh"
echo "Restart application: restart-schemind.sh"
