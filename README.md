# CI/CD Pipeline Automation for Cloud Application Deployment

> **Industry-oriented DevOps project** — automated build, test, containerization, and cloud deployment pipeline using GitHub Actions, Docker, and AWS EC2.

---

## Project Overview

This project demonstrates a complete, production-style CI/CD pipeline that automatically:
1. Runs tests on every code push
2. Builds a Docker container image
3. Pushes it to Docker Hub
4. Deploys it to an AWS EC2 server — with zero manual steps

---

## Tech Stack

| Tool | Purpose |
|---|---|
| Node.js + Express | Web application |
| Git + GitHub | Source control |
| GitHub Actions | CI/CD automation |
| Docker | Containerization |
| Docker Hub | Image registry |
| AWS EC2 (Ubuntu) | Cloud deployment target |
| Shell Scripts | Automation utilities |

---

## Project Structure

```
cicd-demo-project/
├── .github/
│   └── workflows/
│       └── cicd.yml          # GitHub Actions pipeline
├── app/
│   ├── src/
│   │   └── server.js         # Node.js Express server
│   ├── public/
│   │   ├── index.html        # Frontend page
│   │   ├── style.css         # Styles
│   │   └── app.js            # Frontend JS
│   ├── app.test.js           # Jest unit tests
│   ├── package.json
│   └── Dockerfile            # Docker build instructions
├── scripts/
│   ├── setup-ec2.sh          # One-time EC2 setup
│   ├── deploy.sh             # Manual deployment
│   ├── monitor.sh            # Health monitoring
│   └── rollback.sh           # Rollback to previous version
├── docker-compose.yml        # Local dev compose file
├── .gitignore
└── README.md
```

---

## Pipeline Flow

```
Developer pushes code
        │
        ▼
  GitHub Actions triggers
        │
        ├─► [Job 1] Run Tests
        │         npm ci → npm test
        │
        ├─► [Job 2] Build & Push (only if tests pass)
        │         docker build → docker push to Docker Hub
        │
        └─► [Job 3] Deploy to EC2 (only on main branch)
                  SSH → docker pull → docker run → health check
```

---

## Quick Start (Local)

### Prerequisites
- Node.js 18+
- Docker Desktop
- Git

### Run locally with Node.js
```bash
git clone https://github.com/YOUR_USERNAME/cicd-demo-app.git
cd cicd-demo-app/app
npm install
npm start
# Open: http://localhost:3000
```

### Run locally with Docker
```bash
cd cicd-demo-app
docker compose up --build
# Open: http://localhost:3000
```

### Run tests
```bash
cd app
npm test
```

---

## GitHub Secrets Required

Go to GitHub repo → Settings → Secrets and variables → Actions → New repository secret

| Secret Name | Value |
|---|---|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token (not password) |
| `EC2_HOST` | EC2 public IP address |
| `EC2_USER` | `ubuntu` (or your EC2 username) |
| `EC2_SSH_KEY` | Contents of your `.pem` private key file |

---

## AWS EC2 Setup

### 1. Launch EC2 Instance
- AMI: Ubuntu Server 22.04 LTS
- Instance type: t2.micro (free tier)
- Security group inbound rules:
  - Port 22 (SSH) — your IP
  - Port 3000 (App) — Anywhere (0.0.0.0/0)
  - Port 80 (HTTP) — optional

### 2. Run setup script
```bash
# Copy key permissions
chmod 400 your-key.pem

# SSH into EC2
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Download and run setup script
wget https://raw.githubusercontent.com/YOUR_USERNAME/cicd-demo-app/main/scripts/setup-ec2.sh
chmod +x setup-ec2.sh
sudo ./setup-ec2.sh

# Log out and back in (required for Docker group)
exit
ssh -i your-key.pem ubuntu@YOUR_EC2_IP
```

---

## API Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/` | GET | Main web page |
| `/health` | GET | Health check (used by pipeline) |
| `/api/info` | GET | Application info |
| `/api/metrics` | GET | Runtime metrics |

### Example health response
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "environment": "production",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "uptime": 3600,
  "hostname": "ip-172-31-xx-xx"
}
```

---

## Monitoring

Run the monitor script manually or as a cron job:
```bash
# Manual
./scripts/monitor.sh

# Cron (every 5 minutes)
crontab -e
*/5 * * * * /opt/cicd-app/scripts/monitor.sh >> /opt/cicd-app/logs/cron.log 2>&1
```

---

## Rollback

If deployment goes wrong:
```bash
# See available image versions
docker images yourusername/cicd-demo-app

# Rollback to specific version
./scripts/rollback.sh sha-abc1234
```

---

## Resume Description

**Project:** Industry-Oriented CI/CD Pipeline Automation for Cloud Application Deployment

Designed and implemented a complete CI/CD pipeline automating the build, test, and deployment of a Dockerized Node.js web application to AWS EC2. Configured GitHub Actions workflows to trigger automated Jest testing, Docker image builds, and zero-downtime deployments via SSH on every commit to the main branch. Containerized the application using multi-stage Docker builds and published versioned images to Docker Hub. Implemented health checks, deployment rollback scripts, and basic system monitoring using shell scripting on a Linux (Ubuntu) server.

**Tech:** Linux · Git · GitHub · Docker · GitHub Actions · AWS EC2 · Node.js · Shell Scripting

---

## Author

**T. Lokeshwari**  
CSE Student — Agni College of Technology  
Specialization: AI, Machine Learning, Full Stack Development
