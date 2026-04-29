# Jenkins Setup Instructions for Schemind CI/CD Pipeline

## Prerequisites

1. **Jenkins Server** (already installed)
2. **AWS Account** with EC2 access
3. **Docker Hub Account** (faheem313)
4. **GitHub Repository** (https://github.com/theunknownodysseus/Schemind.git)

## Step 1: Configure Jenkins Credentials

### 1.1 Docker Hub Credentials
1. Go to `Manage Jenkins` → `Credentials` → `System` → `Global credentials (unrestricted)`
2. Click `Add Credentials`
3. Select `Username with password`
4. **ID**: `dockerhub-credentials`
5. **Username**: `faheem313`
6. **Password**: `03-Feb-2004`
7. **Description**: `Docker Hub Credentials`

### 1.2 AWS Credentials
1. Click `Add Credentials` again
2. Select `AWS Credentials`
3. **ID**: `aws-credentials`
4. **Access Key ID**: Your AWS Access Key
5. **Secret Access Key**: Your AWS Secret Key
6. **Description**: `AWS Credentials for EC2 deployment`

### 1.3 GitHub Credentials (Optional)
1. Click `Add Credentials` again
2. Select `Username with password`
3. **ID**: `github-credentials`
4. **Username**: Your GitHub username
5. **Password**: Your GitHub Personal Access Token
6. **Description**: `GitHub Credentials`

## Step 2: Install Required Jenkins Plugins

1. Go to `Manage Jenkins` → `Plugins` → `Available plugins`
2. Install these plugins:
   - **Docker Pipeline**
   - **Terraform Plugin**
   - **AWS Credentials Plugin**
   - **Git Plugin** (usually pre-installed)
   - **Workspace Cleanup Plugin**

## Step 3: Create Jenkins Pipeline Job

1. Go to Jenkins Dashboard → `New Item`
2. **Item name**: `Schemind-CI-CD`
3. Select `Pipeline`
4. Click `OK`

### 3.1 Pipeline Configuration
1. **Pipeline script from SCM**
2. **SCM**: Git
3. **Repository URL**: `https://github.com/theunknownodysseus/Schemind.git`
4. **Credentials**: Select `github-credentials` (or none if public repo)
5. **Branch Specifier**: `*/main`
6. **Script Path**: `Jenkinsfile`
7. Click `Save`

## Step 4: AWS Setup

### 4.1 Create IAM User for Terraform
1. Go to AWS Console → IAM → Users → `Create user`
2. **User name**: `jenkins-terraform`
3. **Permissions**: Attach policies:
   - `AmazonEC2FullAccess`
   - `AmazonVPCFullAccess`
   - `AmazonElasticIPFullAccess`
   - `AmazonS3FullAccess` (for Terraform state)

### 4.2 Create S3 Bucket for Terraform State (Optional but recommended)
```bash
aws s3 mb s3://your-terraform-state-bucket-name
```

## Step 5: Run the Pipeline

1. Go to your Jenkins job `Schemind-CI-CD`
2. Click `Build Now`
3. Monitor the build progress

### Pipeline Stages:
1. **Checkout Code** - Pull from GitHub
2. **Setup Node.js** - Install Node.js
3. **Install Dependencies** - Frontend & Backend
4. **Build Application** - React build
5. **Run Tests** - Linting
6. **Build Docker Image** - Multi-stage build
7. **Login to Docker Hub** - Authenticate
8. **Push to Docker Hub** - Push images
9. **Deploy to EC2 with Terraform** - Create EC2 instance

## Step 6: Access Your Application

After successful deployment:
1. Check Jenkins console output for EC2 public IP
2. Access your application at: `http://<EC2_PUBLIC_IP>:3000`

## Troubleshooting

### Common Issues:

1. **Docker Hub Login Failed**
   - Check credentials in Jenkins
   - Verify Docker Hub username/password

2. **AWS Permission Denied**
   - Check AWS credentials
   - Verify IAM user permissions

3. **Terraform Failed**
   - Check AWS region configuration
   - Verify security group settings

4. **EC2 Instance Not Starting**
   - Check AMI ID for your region
   - Verify user data script

### Useful Commands:

```bash
# Check EC2 instance status
aws ec2 describe-instances --instance-ids <INSTANCE_ID>

# Check Docker container on EC2
ssh -i your-key.pem ec2-user@<EC2_IP>
docker ps
docker logs schemind-app

# Terraform commands
terraform init
terraform plan
terraform apply
terraform destroy
```

## Security Notes

1. **Never commit AWS credentials to Git**
2. **Use Jenkins credentials store**
3. **Restrict SSH access to EC2 instances**
4. **Use security groups properly**
5. **Consider using private ECR instead of Docker Hub**

## Cost Optimization

1. **Use t2.micro (Free Tier eligible)**
2. **Stop EC2 instances when not in use**
3. **Monitor AWS costs**
4. **Consider using EC2 Spot Instances**

## Monitoring

1. **Set up CloudWatch alarms**
2. **Monitor application health**
3. **Check Jenkins build history**
4. **Review AWS costs regularly**

---

**Your pipeline is now ready!** 🚀

The Jenkins pipeline will automatically:
- Build your React/Node.js application
- Push Docker images to Docker Hub
- Deploy to AWS EC2 using Terraform
- Provide you with the application URL
