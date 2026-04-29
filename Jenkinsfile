pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'faheem313/schemind'
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
        GITHUB_REPO = 'https://github.com/Fahi-11/Schemind.git'
        AWS_REGION = 'us-east-1'
        EC2_INSTANCE_TYPE = 'c7.flex.large'
        TERRAFORM_DIR = 'terraform'
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                script {
                    // Clean workspace
                    cleanWs()
                    
                    // Checkout from GitHub
                    git branch: 'cicd-pipeline',
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
                    
                    // Verify Terraform directory exists and has files from Git checkout
                    bat '''
                    if not exist terraform\\main.tf (
                        echo ERROR: Terraform files not found in workspace!
                        echo Checking current directory contents:
                        dir /b
                        echo.
                        echo Checking terraform directory:
                        if exist terraform (
                            dir terraform
                        ) else (
                            echo terraform directory does not exist
                        )
                        echo.
                        echo Checking if terraform files exist in repository:
                        dir /b terraform\\*.tf 2>nul || echo No .tf files found in terraform directory
                        exit /b 1
                    ) else (
                        echo Terraform files found successfully:
                        dir terraform\\*.tf
                    )
                    '''
                    
                    // Initialize and apply Terraform with AWS credentials
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']]) {
                        bat '''
                        set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                        set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                        set AWS_DEFAULT_REGION=%AWS_REGION%
                        cd terraform
                        ..\\terraform.exe init -upgrade
                        ..\\terraform.exe validate
                        ..\\terraform.exe plan -var="aws_region=%AWS_REGION%" -var="instance_type=%EC2_INSTANCE_TYPE%" -var="docker_image=%DOCKER_IMAGE%:%BUILD_NUMBER%" -var="tag=%BUILD_NUMBER%" -out=tfplan
                        ..\\terraform.exe apply -auto-approve tfplan
                        '''
                    }
                    
                    // Get EC2 public IP with error handling
                    try {
                        def ec2_ip = bat(script: 'cd terraform && ..\\terraform.exe output -raw ec2_public_ip', returnStdout: true).trim()
                        echo "✅ EC2 Instance deployed successfully!"
                        echo "🌐 Application will be available at: http://${ec2_ip}:3000"
                        echo "🐳 Docker image: ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                        echo "💻 Instance type: ${EC2_INSTANCE_TYPE}"
                        
                        // Wait for application to be ready
                        echo "⏳ Waiting for application to start (60 seconds)..."
                        bat "timeout /t 60 /nobreak >nul"
                        
                        // Health check
                        try {
                            bat "curl -f http://${ec2_ip}:3000 --max-time 10"
                            echo "✅ Application is responding successfully!"
                        } catch (Exception e) {
                            echo "⚠️ Application may still be starting. Please check: http://${ec2_ip}:3000"
                        }
                        
                    } catch (Exception e) {
                        echo "❌ Failed to get EC2 public IP. Check Terraform output."
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Clean up Docker
            bat 'docker logout'
            bat 'docker system prune -f'
            
            // Terraform cleanup (optional - keep state files)
            echo "📋 Terraform state files preserved in terraform directory"
        }
        
        success {
            echo '✅ Pipeline completed successfully!'
            echo "🐳 Docker image: ${DOCKER_IMAGE}:${BUILD_NUMBER}"
            echo "🌐 Image pushed to Docker Hub - ready for deployment"
            echo "🚀 EC2 instance created and application deployed!"
            echo "💻 Instance type: ${EC2_INSTANCE_TYPE}"
            echo "🔗 Check your application at the provided URL"
        }
        
        failure {
            echo '❌ Pipeline failed!'
            echo '🔍 Check the console output for detailed error information'
            echo '📋 Common issues to check:'
            echo '   - Docker Hub credentials'
            echo '   - AWS credentials and permissions'
            echo '   - Terraform configuration files'
            echo '   - Network connectivity'
            
            // Optional: Send email notification
            mail to: 'admin@example.com',
                subject: "Jenkins Pipeline Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "The Jenkins pipeline for ${env.JOB_NAME} failed. Check the console output for details."
        }
        
        unstable {
            echo '⚠️ Pipeline completed with warnings!'
            echo '🔍 Some stages may have issues. Review the logs above.'
        }
    }
}
