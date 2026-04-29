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
                    cleanWs()
                    git branch: 'cicd-pipeline',
                        url: "${GITHUB_REPO}",
                        credentialsId: 'github-credentials'
                }
            }
        }
        
        stage('Build and Push Docker Image') {
            steps {
                script {
                    echo "🐳 Building Docker image..."

                    // Optimize image size
                    echo "📏 Optimizing Docker image size..."
                    bat "docker images ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                    
                    // Push to Docker Hub
                    echo "📤 Pushing to Docker Hub..."
                    withCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIALS_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        bat "echo %DOCKER_PASS% | docker login -u %DOCKER_USER% --password-stdin"
                        bat "docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                    }

                    echo "🧹 Cleaning up intermediate images..."
                    bat "docker image prune -f"
                }
            }
        }
        
        stage('Deploy to EC2 with Terraform') {
            steps {
                script {

                    // Install Terraform if not exists
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

                    // Verify Terraform files
                    bat '''
                    if not exist terraform\\main.tf (
                        echo ERROR: Terraform files not found!
                        dir terraform\\*.tf
                        exit /b 1
                    ) else (
                        echo Terraform files found!
                        dir terraform\\*.tf
                    )
                    '''

                    // Run Terraform
                    withCredentials([$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']) {
                        bat """
                        set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                        set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                        set AWS_DEFAULT_REGION=${AWS_REGION}

                        cd terraform
                        ..\\terraform.exe init -upgrade
                        ..\\terraform.exe validate
                        ..\\terraform.exe plan -var="aws_region=${AWS_REGION}" -var="instance_type=${EC2_INSTANCE_TYPE}" -var="docker_image=${DOCKER_IMAGE}:${BUILD_NUMBER}" -var="tag=${BUILD_NUMBER}" -out=tfplan
                        ..\\terraform.exe apply -auto-approve tfplan
                        """
                    }

                    // Get EC2 IP
                    def ec2_ip_cmd = bat(script: 'cd terraform && ..\\terraform.exe output -raw ec2_public_ip', returnStdout: true).trim()
                    def ec2_ip = ec2_ip_cmd.split('\\n')[0].trim()

                    env.EC2_IP = ec2_ip

                    echo "✅ EC2 deployed!"
                    echo "🌐 App URL: http://${env.EC2_IP}:3000"

                    // Wait for app
                    echo "⏳ Waiting for app to start..."
                    bat "ping -n 60 127.0.0.1 >nul"

                    // Health check
                    bat """
                    powershell -Command "
                    \$url = 'http://${env.EC2_IP}:3000'
                    try {
                        \$res = Invoke-WebRequest -Uri \$url -TimeoutSec 10 -UseBasicParsing
                        if (\$res.StatusCode -eq 200) {
                            Write-Host '✅ App is running!'
                        } else {
                            Write-Host '⚠️ Status: ' \$res.StatusCode
                        }
                    } catch {
                        Write-Host '⚠️ App still starting... Check manually.'
                    }
                    "
                    """
                }
            }
        }
    }
    
    post {
        always {
            bat 'docker logout'
            bat 'docker system prune -f'
            echo "📋 Cleanup done"
        }
        
        success {
            echo "🎉 Pipeline SUCCESS!"
            echo "🐳 Image: ${DOCKER_IMAGE}:${BUILD_NUMBER}"
            echo "🌐 URL: http://${env.EC2_IP}:3000"
        }
        
        failure {
            echo "❌ Pipeline FAILED!"
            echo "Check logs for errors:"
            echo "- Docker issues"
            echo "- Git checkout failure"
            echo "- Terraform errors"
            echo "- AWS credentials issues"
        }
    }
}