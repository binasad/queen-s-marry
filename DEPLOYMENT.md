# 🚀 Deployment Guide

## AWS Deployment Checklist

### 1️⃣ Prepare Application

```bash
# Install production dependencies
cd backend
npm install --production

# Build optimizations
npm run build  # If using TypeScript
```

### 2️⃣ Setup AWS RDS (PostgreSQL)

```bash
# Create RDS instance via AWS Console or CLI
aws rds create-db-instance \
  --db-instance-identifier salon-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 16.1 \
  --master-username admin \
  --master-user-password [SECURE_PASSWORD] \
  --allocated-storage 20 \
  --storage-encrypted \
  --backup-retention-period 7 \
  --multi-az

# Run migrations
export DATABASE_URL="postgresql://admin:password@salon-db.xxx.rds.amazonaws.com:5432/salon"
npm run db:migrate
```

### 3️⃣ Setup S3 Bucket

```bash
# Create S3 bucket
aws s3api create-bucket \
  --bucket salon-app-images \
  --region us-east-1

# Set bucket policy for public read
aws s3api put-bucket-policy \
  --bucket salon-app-images \
  --policy file://s3-policy.json

# Enable CORS
aws s3api put-bucket-cors \
  --bucket salon-app-images \
  --cors-configuration file://cors-config.json
```

### 4️⃣ Deploy to EC2/Elastic Beanstalk

**Option A: EC2**
```bash
# SSH into EC2
ssh -i key.pem ec2-user@your-instance-ip

# Install Node.js
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Clone and setup
git clone your-repo
cd backend
npm install --production
npm install -g pm2

# Start with PM2
pm2 start src/server.js --name salon-api
pm2 startup
pm2 save
```

**Option B: Elastic Beanstalk**
```bash
# Install EB CLI
pip install awsebcli

# Initialize
eb init -p node.js-18 salon-api

# Create environment
eb create salon-production

# Deploy
eb deploy
```

### 5️⃣ Setup Load Balancer (ALB)

```bash
# Create target group
aws elbv2 create-target-group \
  --name salon-api-tg \
  --protocol HTTP \
  --port 5000 \
  --vpc-id vpc-xxx

# Create load balancer
aws elbv2 create-load-balancer \
  --name salon-api-alb \
  --subnets subnet-xxx subnet-yyy \
  --security-groups sg-xxx

# Register targets
aws elbv2 register-targets \
  --target-group-arn arn:aws:elasticloadbalancing:... \
  --targets Id=i-xxx
```

### 6️⃣ Configure SSL Certificate

```bash
# Request certificate via ACM
aws acm request-certificate \
  --domain-name api.yourdomain.com \
  --validation-method DNS

# Add HTTPS listener to ALB
aws elbv2 create-listener \
  --load-balancer-arn arn:... \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=arn:... \
  --default-actions Type=forward,TargetGroupArn=arn:...
```

### 7️⃣ Setup CI/CD with GitHub Actions

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to AWS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: |
          cd backend
          npm ci
      
      - name: Run tests
        run: npm test
      
      - name: Deploy to EB
        uses: einaregilsson/beanstalk-deploy@v21
        with:
          aws_access_key: ${{ secrets.AWS_ACCESS_KEY }}
          aws_secret_key: ${{ secrets.AWS_SECRET_KEY }}
          region: us-east-1
          application_name: salon-api
          environment_name: salon-production
          version_label: ${{ github.sha }}
```

### 8️⃣ Environment Variables

```bash
# Set in AWS Systems Manager Parameter Store
aws ssm put-parameter --name /salon/DB_HOST --value "xxx.rds.amazonaws.com" --type SecureString
aws ssm put-parameter --name /salon/DB_PASSWORD --value "xxx" --type SecureString
aws ssm put-parameter --name /salon/JWT_SECRET --value "xxx" --type SecureString
```

### 9️⃣ Monitoring & Logging

```bash
# Setup CloudWatch Logs
aws logs create-log-group --log-group-name /aws/salon-api

# Install CloudWatch agent on EC2
sudo yum install -y amazon-cloudwatch-agent

# Configure CloudWatch metrics
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json << EOF
{
  "metrics": {
    "namespace": "SalonApp",
    "metrics_collected": {
      "mem": {"measurement": [{"name": "mem_used_percent"}]},
      "disk": {"measurement": [{"name": "disk_used_percent"}]}
    }
  }
}
EOF

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json \
  -s
```

### 🔟 Post-Deployment Verification

```bash
# Health check
curl https://api.yourdomain.com/health

# Run load test
npm install -g artillery
artillery quick --count 100 -n 50 https://api.yourdomain.com/api/v1/services

# Check logs
aws logs tail /aws/salon-api --follow
```

---

## Cost Estimation (Monthly)

| Service | Configuration | Estimated Cost |
|---------|--------------|----------------|
| EC2 (t3.medium x2) | 2 instances | $60 |
| RDS (db.t3.micro) | Single-AZ | $15 |
| S3 | 100GB storage | $2.30 |
| Data Transfer | 100GB out | $9 |
| ALB | 1 load balancer | $16 |
| **Total** | | **~$102/month** |

---

## Production Checklist

- [ ] Environment variables configured
- [ ] Database migrations run
- [ ] SSL certificate installed
- [ ] CORS configured
- [ ] Rate limiting enabled
- [ ] Monitoring setup
- [ ] Backup strategy configured
- [ ] CI/CD pipeline working
- [ ] Load testing completed
- [ ] Security audit passed
- [ ] Documentation updated
- [ ] Error tracking configured (Sentry)
- [ ] DNS records updated
- [ ] Health checks configured
