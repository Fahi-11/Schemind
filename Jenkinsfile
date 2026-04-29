pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'faheem313/schemind'
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
        GITHUB_REPO = 'https://github.com/theunknownodysseus/Schemind.git'
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                script {
                    // Clean workspace
                    cleanWs()
                    
                    // Checkout from GitHub
                    git branch: 'main',
                        url: "${GITHUB_REPO}",
                        credentialsId: 'github-credentials'
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    // Create Dockerfile for Windows - fixed version
                    bat '''
                    echo # Multi-stage build for Schemind > Dockerfile
                    echo FROM node:20-alpine AS frontend-builder >> Dockerfile
                    echo. >> Dockerfile
                    echo WORKDIR /app/frontend >> Dockerfile
                    echo. >> Dockerfile
                    echo # Copy frontend package files >> Dockerfile
                    echo COPY package*.json ./ >> Dockerfile
                    echo COPY tsconfig*.json ./ >> Dockerfile
                    echo COPY vite.config.ts ./ >> Dockerfile
                    echo COPY tailwind.config.js ./ >> Dockerfile
                    echo COPY postcss.config.js ./ >> Dockerfile
                    echo. >> Dockerfile
                    echo # Install ALL dependencies (including devDependencies) >> Dockerfile
                    echo RUN npm ci >> Dockerfile
                    echo. >> Dockerfile
                    echo # Copy frontend source code >> Dockerfile
                    echo COPY src/ ./src/ >> Dockerfile
                    echo COPY index.html ./ >> Dockerfile
                    echo. >> Dockerfile
                    echo # Create public directory if it doesn't exist >> Dockerfile
                    echo RUN mkdir -p ./public || true >> Dockerfile
                    echo # Copy favicon if exists >> Dockerfile
                    echo COPY favicon.ico ./public/ || true >> Dockerfile
                    echo. >> Dockerfile
                    echo # Build frontend >> Dockerfile
                    echo RUN npm run build >> Dockerfile
                    echo. >> Dockerfile
                    echo # Backend stage >> Dockerfile
                    echo FROM node:20-alpine AS backend >> Dockerfile
                    echo. >> Dockerfile
                    echo WORKDIR /app >> Dockerfile
                    echo. >> Dockerfile
                    echo # Install system dependencies >> Dockerfile
                    echo RUN apk add --no-cache python3 make g++ >> Dockerfile
                    echo. >> Dockerfile
                    echo # Copy backend package files >> Dockerfile
                    echo COPY backend/package*.json ./ >> Dockerfile
                    echo. >> Dockerfile
                    echo # Install backend dependencies (use npm install since no lockfile) >> Dockerfile
                    echo RUN npm install --omit=dev >> Dockerfile
                    echo. >> Dockerfile
                    echo # Copy backend source code >> Dockerfile
                    echo COPY backend/server.js ./ >> Dockerfile
                    echo. >> Dockerfile
                    echo # Copy built frontend from previous stage >> Dockerfile
                    echo COPY --from=frontend-builder /app/frontend/dist ./public >> Dockerfile
                    echo. >> Dockerfile
                    echo # Create non-root user >> Dockerfile
                    echo RUN addgroup -g 1001 -S nodejs >> Dockerfile
                    echo RUN adduser -S nodejs -u 1001 >> Dockerfile
                    echo. >> Dockerfile
                    echo # Change ownership of the app directory >> Dockerfile
                    echo RUN chown -R nodejs:nodejs /app >> Dockerfile
                    echo USER nodejs >> Dockerfile
                    echo. >> Dockerfile
                    echo # Expose port >> Dockerfile
                    echo EXPOSE 3000 >> Dockerfile
                    echo. >> Dockerfile
                    echo # Start the application >> Dockerfile
                    echo CMD ["node", "server.js"] >> Dockerfile
                    '''
                    
                    // Build Docker image
                    bat "docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} ."
                    bat "docker build -t ${DOCKER_IMAGE}:latest ."
                    
                    echo "Docker image built successfully"
                }
            }
        }
        
        stage('Login to Docker Hub') {
            steps {
                script {
                    // Login to Docker Hub using Jenkins credentials
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        bat 'echo %DOCKER_PASS% | docker login -u "%DOCKER_USER%" --password-stdin'
                    }
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    // Push images to Docker Hub
                    bat "docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                    bat "docker push ${DOCKER_IMAGE}:latest"
                    
                    echo "Images pushed to Docker Hub successfully"
                }
            }
        }
        
        stage('Deploy to EC2 with Terraform') {
            steps {
                script {
                    // Install Terraform (Windows)
                    bat '''
                    if not exist terraform.exe (
                        echo Downloading Terraform...
                        powershell -Command "Invoke-WebRequest -Uri 'https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_windows_amd64.zip' -OutFile 'terraform.zip'"
                        powershell -Command "Expand-Archive -Path 'terraform.zip' -DestinationPath '.'"
                        del terraform.zip
                    ) else (
                        echo Terraform already exists
                    )
                    terraform.exe version
                    '''
                    
                    // Initialize and apply Terraform with AWS credentials using external files
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        bat '''
                        set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                        set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                        set AWS_DEFAULT_REGION=%AWS_REGION%
                        cd terraform
                        ..\\terraform.exe init
                        ..\\terraform.exe plan -var="aws_region=us-east-1" -var="instance_type=c7.flex.large" -var="docker_image=%DOCKER_IMAGE%:%BUILD_NUMBER%" -var="tag=%BUILD_NUMBER%" -out=tfplan
                        ..\\terraform.exe apply -auto-approve tfplan
                        '''
                    }
                    
                    // Get EC2 public IP
                    def ec2_ip = bat(script: 'cd terraform && ..\\terraform.exe output -raw ec2_public_ip', returnStdout: true).trim()
                    
                    echo "✅ EC2 Instance deployed successfully!"
                    echo "🌐 Application will be available at: http://${ec2_ip}:3000"
                    echo "🐳 Docker image: ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                    echo "💻 Instance type: c7.flex.large"
                }
            }
        }
    }
    
    post {
        always {
            // Clean up Docker
            bat 'docker logout'
            bat 'docker system prune -f'
        }
        
        success {
            echo '✅ Pipeline completed successfully!'
            echo "🐳 Docker image: ${DOCKER_IMAGE}:${BUILD_NUMBER}"
            echo "🌐 Image pushed to Docker Hub - ready for deployment"
            echo "🚀 EC2 instance created and application deployed!"
        }
        
        failure {
            echo '❌ Pipeline failed!'
            mail to: 'admin@example.com',
                subject: "Jenkins Pipeline Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "The Jenkins pipeline for ${env.JOB_NAME} failed. Check the console output for details."
        }
        
        unstable {
            echo '⚠️ Pipeline completed with warnings!'
        }
    }
}
