pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'faheem313/schemind'
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
        GITHUB_REPO = 'https://github.com/Fahi-11/Schemind.git'
        AWS_REGION = 'us-east-1'
        EC2_INSTANCE_TYPE = 't3.small'
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
        
        stage('Build and Push Docker Image') {
            steps {
                script {
                    // Use optimized multi-stage Dockerfile
                    echo "🐳 Building optimized Docker image..."
                    
                    // Build with BuildKit for better caching and parallel builds
                    bat '''
                    set DOCKER_BUILDKIT=1
                    docker build --no-cache -t ${DOCKER_IMAGE}:${BUILD_NUMBER} -f Dockerfile.optimized .
                    '''
                    
                    // Optimize image size
                    echo "📏 Optimizing Docker image size..."
                    bat "docker images ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                    
                    // Push to Docker Hub
                    echo "📤 Pushing to Docker Hub..."
                    withCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIALS_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        bat "echo %DOCKER_PASS% | docker login -u %DOCKER_USER% --password-stdin"
                        bat "docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                    }
                    
                    // Clean up intermediate images
                    echo "🧹 Cleaning up intermediate Docker images..."
                    bat "docker image prune -f --filter label=stage=builder"
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
                    
                    // Verify Terraform directory exists and has files from Git checkout
                    bat '''
                    if not exist terraform\\main.tf (
                        echo ERROR: Terraform files not found in workspace!
                        dir terraform\\*.tf
                        exit /b 1
                    ) else (
                        echo Terraform files found successfully!
                        dir terraform\\*.tf
                    )
                    '''
                    
                    // Initialize and apply Terraform with AWS credentials
                    withCredentials([$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']) {
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
                        script {
                            def ec2_ip_cmd = bat(script: 'cd terraform && ..\\terraform.exe output -raw ec2_public_ip', returnStdout: true).trim()
                            def ec2_ip = ec2_ip_cmd.split('\\n')[0].trim()
                            echo "✅ EC2 Instance deployed successfully!"
                            echo "🌐 Application will be available at: http://${ec2_ip}:3000"
                            echo "🐳 Docker image: ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                            echo "💻 Instance type: ${EC2_INSTANCE_TYPE}"
                            
                            // Wait for application to be ready
                            echo "⏳ Waiting for application to start (60 seconds)..."
                            bat "ping -n 60 127.0.0.1 >nul"
                            
                            // Health check
                            try {
                                def url = "http://${ec2_ip}:3000"
                                powershell """
                                \$url = \"${url}\"
                                try {
                                    \$response = Invoke-WebRequest -Uri \$url -TimeoutSec 10 -UseBasicParsing
                                    if (\$response.StatusCode -eq 200) {
                                        Write-Host \"✅ Application is responding successfully!\"
                                    } else {
                                        Write-Host \"⚠️ Application returned status code: \$($response.StatusCode)\"
                                    }
                                } catch {
                                    Write-Host \"⚠️ Application may still be starting. Please check: \$url\"
                                }
                                """
                            } catch (Exception e) {
                                echo "⚠️ Health check failed. Please check: http://${ec2_ip}:3000"
                            }
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
            echo "🎉 Pipeline completed successfully!"
            echo "🐳 Docker image: ${DOCKER_IMAGE}:${BUILD_NUMBER}"
            echo "🌐 Image pushed to Docker Hub - ready for deployment"
            echo "🚀 EC2 instance created and application deployed!"
            echo "💻 Instance type: ${EC2_INSTANCE_TYPE}"
            echo "🔗 Check your application at: http://${ec2_ip}:3000"
        }
        
        failure {
            echo "❌ Pipeline failed!"
            echo "🔍 Check the logs above for error details"
            echo "📧 Common issues:"
            echo "  - Docker daemon not running"
            echo "  - Git checkout failed"
            echo "  - Terraform execution failed"
            echo "  - AWS credentials missing"
            echo "  - Docker Hub login failed"
        }
    }
}
