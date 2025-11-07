# 🚀 Jenkins Quick Start Commands

## 📦 **Installation Commands**

### **Option 1: Docker (Recommended)**
```powershell
# Create Jenkins home directory
mkdir C:\jenkins_home

# Run Jenkins container with Docker access
docker run -d `
  --name jenkins `
  -p 8080:8080 -p 50000:50000 `
  -v C:\jenkins_home:/var/jenkins_home `
  -v /var/run/docker.sock:/var/run/docker.sock `
  jenkins/jenkins:lts

# Get initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# View logs
docker logs -f jenkins
```

### **Option 2: Chocolatey**
```powershell
choco install jenkins
net start jenkins
```

---

## 🐳 **SonarQube Setup**

```powershell
# Run SonarQube
docker run -d `
  --name sonarqube `
  -p 9000:9000 `
  sonarqube:lts-community

# Check status
docker logs -f sonarqube

# Access: http://localhost:9000
# Login: admin / admin
```

---

## ☸️ **Minikube Setup (for K8s deployment)**

```powershell
# Install
choco install minikube

# Start cluster
minikube start

# Check status
minikube status
kubectl get nodes

# Dashboard
minikube dashboard
```

---

## 🔧 **Jenkins Access**

- **URL**: http://localhost:8080
- **Admin Password**: Check with docker command above
- **Plugins to Install**:
  - Git Plugin
  - GitHub Plugin
  - Docker Pipeline
  - SonarQube Scanner
  - Kubernetes CLI
  - HTML Publisher
  - Pytest Plugin

---

## 🧪 **Test Pipeline Locally**

```powershell
cd C:\Users\sriva\Downloads\Devops_A2\Solution

# Run what Jenkins will run:

# 1. Install dependencies
pip install -r requirements.txt

# 2. Lint code
flake8 app/ --max-line-length=120 --exclude=__pycache__

# 3. Run tests with coverage
pytest -v --cov=app --cov-report=xml --cov-report=html

# 4. Build Docker image
docker build -t aceest-fitness:test .

# 5. Test Docker container
docker run -d --name test-app -p 5001:5000 aceest-fitness:test
curl http://localhost:5001/health
docker stop test-app
docker rm test-app
```

---

## 🔔 **Setup Webhook (for auto-trigger)**

### **Option A: Using ngrok (local Jenkins)**
```powershell
# Install ngrok
choco install ngrok

# Expose Jenkins
ngrok http 8080

# Copy the HTTPS URL (e.g., https://abc123.ngrok.io)
# Add to GitHub: Settings → Webhooks
# Payload URL: https://abc123.ngrok.io/github-webhook/
```

### **Option B: Public Server**
```
GitHub → Repository → Settings → Webhooks
URL: http://YOUR_SERVER:8080/github-webhook/
Content type: application/json
Events: Just the push event
```

---

## 📊 **Useful Jenkins Commands**

```powershell
# Restart Jenkins (Docker)
docker restart jenkins

# Stop Jenkins
docker stop jenkins

# Start Jenkins
docker start jenkins

# Remove Jenkins (keeps data in C:\jenkins_home)
docker rm jenkins

# Complete removal (WARNING: deletes all data)
docker rm -f jenkins
Remove-Item -Recurse -Force C:\jenkins_home
```

---

## 🔍 **Debugging**

```powershell
# Check Jenkins logs
docker logs jenkins

# Check SonarQube logs
docker logs sonarqube

# Enter Jenkins container
docker exec -it jenkins bash

# Check running containers
docker ps

# Check Docker images
docker images

# Test webhook from GitHub
# GitHub → Settings → Webhooks → Recent Deliveries → Redeliver
```

---

## ✅ **Verification Checklist**

After setup, verify:

- [ ] Jenkins accessible at http://localhost:8080
- [ ] SonarQube accessible at http://localhost:9000
- [ ] Docker can build images: `docker build -t test .`
- [ ] Python/pip available in Jenkins
- [ ] GitHub webhook configured
- [ ] Credentials added (GitHub, Docker Hub)
- [ ] Pipeline job created
- [ ] First build successful

---

## 🎯 **Expected Pipeline Result**

When you push to GitHub:

1. ✅ Webhook triggers Jenkins
2. ✅ Jenkins checks out code
3. ✅ Installs dependencies
4. ✅ Runs linting (flake8, pylint)
5. ✅ Runs 40 unit tests
6. ✅ Generates coverage report (95%+)
7. ✅ SonarQube analyzes code
8. ✅ Quality gate passes
9. ✅ Docker image built
10. ✅ Image tested
11. ✅ Pushed to Docker Hub
12. ✅ Deployed to Kubernetes

**Total time**: ~3-5 minutes per build

---

## 🚨 **Common Issues & Solutions**

### **Issue: Port 8080 already in use**
```powershell
# Use different port
docker run -d --name jenkins -p 8081:8080 -p 50000:50000 ...
# Access: http://localhost:8081
```

### **Issue: Docker not found in Jenkins**
```powershell
# Ensure Docker socket is mounted
docker run -v /var/run/docker.sock:/var/run/docker.sock ...
```

### **Issue: Permission denied on Docker socket**
```powershell
# Run Jenkins with Docker group (Linux/Mac)
# Or use Docker Desktop on Windows (handles permissions)
```

### **Issue: Python/pip not found**
```powershell
# Install Python in Jenkins container
docker exec -u root jenkins apt-get update
docker exec -u root jenkins apt-get install -y python3 python3-pip
```

---

**Ready to start?** Follow JENKINS_SETUP.md for detailed step-by-step guide! 🚀
