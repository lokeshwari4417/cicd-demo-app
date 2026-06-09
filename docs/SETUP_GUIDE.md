# Complete Setup Guide
## CI/CD Pipeline Automation for Cloud Application Deployment

---

## PART 1: Set Up Your Local Development Environment

### Step 1.1 — Install Required Tools (Windows)

**Install Git:**
1. Go to https://git-scm.com/downloads
2. Download Git for Windows, run installer (keep all defaults)
3. Verify: open Command Prompt → type `git --version`

**Install Node.js:**
1. Go to https://nodejs.org
2. Download the LTS version (18.x or higher)
3. Run installer (keep all defaults)
4. Verify: open Command Prompt → type `node --version` and `npm --version`

**Install Docker Desktop:**
1. Go to https://www.docker.com/products/docker-desktop
2. Download for Windows, run installer
3. Restart your computer after installation
4. Open Docker Desktop — wait for it to say "Docker is running"
5. Verify: open Command Prompt → type `docker --version`

---

### Step 1.2 — Create Your Project

Open Command Prompt or Git Bash and run:

```bash
# Create a folder for your project
mkdir cicd-demo-app
cd cicd-demo-app

# Initialize git
git init

# Create the folder structure
mkdir -p app/src
mkdir -p app/public
mkdir -p .github/workflows
mkdir -p scripts
mkdir -p docs
```

Now copy all the files from this project into the correct folders.

---

### Step 1.3 — Test the App Locally

```bash
# Go into the app folder
cd app

# Install dependencies
npm install

# Run tests
npm test
# You should see: 7 tests passed ✓

# Start the server
npm start
# Output: DevOps Demo App v1.0.0 | Port: 3000
```

Open your browser: http://localhost:3000
- You should see the application homepage
- Visit http://localhost:3000/health — should return JSON

---

### Step 1.4 — Test with Docker Locally

```bash
# Go back to project root
cd ..

# Build the Docker image
docker build -t cicd-demo-app:local ./app

# Run the container
docker run -d -p 3000:3000 --name test-app cicd-demo-app:local

# Check it's running
docker ps
# Should show: cicd-demo-app running

# Test health endpoint
curl http://localhost:3000/health
# OR open: http://localhost:3000

# View logs
docker logs test-app

# Stop and remove test container
docker stop test-app
docker rm test-app
```

---

## PART 2: Push to GitHub

### Step 2.1 — Create GitHub Repository

1. Go to https://github.com and sign in (or create account)
2. Click the **+** button (top right) → **New repository**
3. Repository name: `cicd-demo-app`
4. Set to **Public**
5. Do NOT check "Add README" (we already have one)
6. Click **Create repository**
7. Copy the repository URL (e.g. `https://github.com/yourusername/cicd-demo-app.git`)

---

### Step 2.2 — Push Your Code

```bash
# Configure git with your info (do this once)
git config --global user.name "Your Name"
git config --global user.email "your@email.com"

# Make sure you're in the project root
cd cicd-demo-app

# Add all files
git add .

# Create first commit
git commit -m "Initial commit: Add CI/CD pipeline project"

# Add GitHub as remote origin
git remote add origin https://github.com/YOUR_USERNAME/cicd-demo-app.git

# Push to GitHub
git push -u origin main
```

Go to your GitHub repository — you should see all your files there.

---

## PART 3: Set Up Docker Hub

### Step 3.1 — Create Docker Hub Account

1. Go to https://hub.docker.com
2. Sign up for a free account (remember your username)
3. Verify your email

### Step 3.2 — Create Access Token

1. Log into Docker Hub
2. Click your profile icon (top right) → **Account Settings**
3. Click **Security** in left sidebar
4. Click **New Access Token**
5. Name: `github-actions-token`
6. Access permissions: **Read, Write, Delete**
7. Click **Generate**
8. **COPY THE TOKEN NOW** — it won't be shown again!
9. Save it somewhere safe (like Notepad temporarily)

---

## PART 4: Set Up AWS EC2

### Step 4.1 — Create AWS Account

1. Go to https://aws.amazon.com
2. Click **Create an AWS Account**
3. Follow the signup process
4. You need a credit card but t2.micro is FREE TIER eligible

### Step 4.2 — Launch EC2 Instance

1. Log into AWS Console
2. Search for **EC2** → Click it
3. Click **Launch Instance**
4. Fill in:
   - **Name:** `cicd-demo-server`
   - **AMI:** Ubuntu Server 22.04 LTS (Free tier eligible)
   - **Instance type:** t2.micro (Free tier eligible)
   - **Key pair:** Click "Create new key pair"
     - Name: `cicd-key`
     - Type: RSA
     - Format: .pem
     - Click "Create key pair" — it will download automatically
   - **Network settings:** Check these boxes:
     - ✅ Allow SSH traffic from: My IP
     - ✅ Allow HTTP traffic
5. Click **Launch Instance**

### Step 4.3 — Configure Security Group

1. After launching, click on your instance name
2. Scroll down → click **Security** tab
3. Click on the security group link
4. Click **Edit inbound rules**
5. Add rule: Type=Custom TCP, Port=3000, Source=Anywhere (0.0.0.0/0)
6. Click **Save rules**

### Step 4.4 — Get Your EC2 IP Address

1. Go back to EC2 → Instances
2. Click on your instance
3. Copy the **Public IPv4 address** (e.g. `54.123.45.678`)

### Step 4.5 — SSH into EC2 and Run Setup Script

On Windows, open Git Bash (or use Windows Terminal):

```bash
# Move key to a safe location and set permissions
# On Windows Git Bash:
chmod 400 ~/Downloads/cicd-key.pem

# SSH into your server (replace with your actual IP)
ssh -i ~/Downloads/cicd-key.pem ubuntu@54.123.45.678
# Type 'yes' when asked about fingerprint

# You are now inside the EC2 server!
# Your terminal prompt changes to: ubuntu@ip-172-...

# Download and run the setup script
curl -o setup-ec2.sh https://raw.githubusercontent.com/YOUR_USERNAME/cicd-demo-app/main/scripts/setup-ec2.sh
chmod +x setup-ec2.sh
sudo ./setup-ec2.sh

# Wait for it to finish (takes 2-3 minutes)

# Log out and back in (required for docker group)
exit
ssh -i ~/Downloads/cicd-key.pem ubuntu@54.123.45.678

# Test Docker works without sudo
docker --version
docker ps
```

### Step 4.6 — Get Your SSH Private Key for GitHub

You need the CONTENTS of your .pem file:

```bash
# On Windows, open Git Bash:
cat ~/Downloads/cicd-key.pem
# Copy everything including -----BEGIN RSA PRIVATE KEY----- and -----END-----
```

---

## PART 5: Configure GitHub Secrets

These are secret values that GitHub Actions uses during the pipeline.

1. Go to your GitHub repository
2. Click **Settings** (top menu)
3. Click **Secrets and variables** (left sidebar) → **Actions**
4. Click **New repository secret** for each:

| Secret Name | What to enter |
|---|---|
| `DOCKERHUB_USERNAME` | Your Docker Hub username (e.g. `lokeshwari123`) |
| `DOCKERHUB_TOKEN` | The access token you saved from Step 3.2 |
| `EC2_HOST` | Your EC2 IP address (e.g. `54.123.45.678`) |
| `EC2_USER` | `ubuntu` |
| `EC2_SSH_KEY` | The full contents of your `.pem` key file |

---

## PART 6: Trigger the Pipeline

### Step 6.1 — Make a Small Code Change and Push

```bash
# On your local machine, inside the project folder
# Edit app/public/index.html — change any visible text

# Commit the change
git add .
git commit -m "feat: update homepage text - trigger pipeline"
git push origin main
```

### Step 6.2 — Watch the Pipeline Run

1. Go to your GitHub repository
2. Click the **Actions** tab
3. You should see "CI/CD Pipeline" running
4. Click on it to watch live logs
5. You'll see 3 jobs:
   - ✅ Run Tests
   - ✅ Build & Push Docker Image
   - ✅ Deploy to EC2

### Step 6.3 — Verify Deployment

Open your browser and go to:
```
http://YOUR_EC2_IP:3000
```

You should see the live application! 🎉

Also test the health endpoint:
```
http://YOUR_EC2_IP:3000/health
```

---

## PART 7: Monitoring

### Set Up Cron Job on EC2

```bash
# SSH into EC2
ssh -i ~/Downloads/cicd-key.pem ubuntu@YOUR_EC2_IP

# Download monitoring script
curl -o /opt/cicd-app/scripts/monitor.sh \
  https://raw.githubusercontent.com/YOUR_USERNAME/cicd-demo-app/main/scripts/monitor.sh
chmod +x /opt/cicd-app/scripts/monitor.sh

# Edit crontab
crontab -e
# Press 'i' to insert, add this line:
*/5 * * * * /opt/cicd-app/scripts/monitor.sh >> /opt/cicd-app/logs/cron.log 2>&1
# Press Esc, then :wq to save

# Run manually to test
/opt/cicd-app/scripts/monitor.sh
```

### View Application Logs

```bash
# View live container logs
docker logs cicd-demo-app -f

# View last 50 lines
docker logs cicd-demo-app --tail=50

# View deployment logs
cat /opt/cicd-app/logs/deploy.log

# View monitoring alerts
cat /opt/cicd-app/logs/alerts.log
```

---

## PART 8: Common Commands Reference

```bash
# ---- LOCAL DEVELOPMENT ----
npm install           # Install dependencies
npm start             # Start server
npm test              # Run tests
npm run dev           # Start with hot-reload (nodemon)

# ---- DOCKER (local) ----
docker build -t myapp ./app        # Build image
docker run -d -p 3000:3000 myapp   # Run container
docker ps                          # List running containers
docker logs <name>                 # View logs
docker stop <name>                 # Stop container
docker rm <name>                   # Remove container
docker images                      # List images
docker image prune                 # Remove unused images

# ---- GIT ----
git status                         # Check status
git add .                          # Stage all changes
git commit -m "message"            # Commit
git push origin main               # Push to GitHub
git log --oneline                  # View commit history

# ---- EC2 / LINUX ----
sudo systemctl status docker       # Check Docker service
docker ps                          # Running containers
free -h                            # Memory usage
df -h                              # Disk usage
top                                # CPU/Memory live monitor
```

---

## Troubleshooting

**Tests fail in GitHub Actions:**
- Check if `app/package.json` has jest in devDependencies
- Ensure `working-directory: ./app` in the workflow

**Docker build fails:**
- Check Dockerfile path in workflow: `context: ./app`
- Verify `.dockerignore` doesn't exclude needed files

**Deployment SSH fails:**
- Ensure EC2 security group allows port 22 from GitHub Actions IPs
- Verify EC2_SSH_KEY secret includes the full key with BEGIN/END lines
- Confirm EC2_USER is `ubuntu` for Ubuntu AMI

**App not accessible on port 3000:**
- EC2 security group inbound rule for port 3000 must be 0.0.0.0/0
- Run: `docker ps` — container must show "Up" status
- Run: `curl http://localhost:3000/health` on the EC2 server itself

**Health check fails after deploy:**
- App might be starting slowly; increase `sleep 8` in deploy script
- Check logs: `docker logs cicd-demo-app`
