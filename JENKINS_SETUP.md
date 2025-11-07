# 🚀 Jenkins CI/CD Pipeline Setup Guide

Complete guide to set up Jenkins for ACEest Fitness & Gym CI/CD pipeline.

---

## 📋 **Prerequisites**

- ✅ Java 11 or 17 installed
- ✅ Docker installed and running
- ✅ Git installed
- ✅ Python 3.11+ installed
- ✅ GitHub repository access
- ✅ Docker Hub account

---

## 🔧 **Step 1: Install Jenkins**

### **Option A: Install Jenkins on Windows**

#### **1.1 Download Jenkins**
```powershell
# Download Jenkins Windows installer
# Visit: https://www.jenkins.io/download/
# Or use Chocolatey:
choco install jenkins
```

#### **1.2 Start Jenkins**
```powershell
# Jenkins will start automatically after installation
# Access at: http://localhost:8080

# To start/stop manually:
net start jenkins
net stop jenkins
```

### **Option B: Run Jenkins in Docker (Recommended)**

```powershell
# Create Jenkins home directory
mkdir C:\jenkins_home

# Run Jenkins container
docker run -d `
  --name jenkins `
  -p 8080:8080 -p 50000:50000 `
  -v C:\jenkins_home:/var/jenkins_home `
  -v /var/run/docker.sock:/var/run/docker.sock `
  jenkins/jenkins:lts
```

#### **1.3 Get Initial Admin Password**

```powershell
# For Docker installation:
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# For Windows installation:
cat C:\Program Files\Jenkins\secrets\initialAdminPassword
```

---

## 🌐 **Step 2: Initial Jenkins Configuration**

### **2.1 Access Jenkins**
1. Open browser: `http://localhost:8080`
2. Enter the initial admin password
3. Click "Install suggested plugins"
4. Create first admin user
5. Configure Jenkins URL: `http://localhost:8080`

### **2.2 Install Required Plugins**

Go to: **Manage Jenkins → Plugins → Available plugins**

Search and install:
- ✅ **Git Plugin** (usually pre-installed)
- ✅ **GitHub Plugin**
- ✅ **Pipeline Plugin** (usually pre-installed)
- ✅ **Docker Pipeline Plugin**
- ✅ **SonarQube Scanner Plugin**
- ✅ **Kubernetes CLI Plugin**
- ✅ **Pytest Plugin**
- ✅ **HTML Publisher Plugin**
- ✅ **Coverage Plugin**

After installation, restart Jenkins:
```powershell
# For Docker:
docker restart jenkins
```

---

## 🔑 **Step 3: Configure Credentials**

### **3.1 GitHub Credentials**

1. Go to: **Manage Jenkins → Credentials → System → Global credentials**
2. Click "Add Credentials"
3. Select "Username with password"
   - **Username**: Your GitHub username
   - **Password**: Personal Access Token (PAT)
   - **ID**: `github-credentials`
   - **Description**: GitHub Access

**Generate GitHub PAT:**
- Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
- Generate new token with scopes: `repo`, `admin:repo_hook`

### **3.2 Docker Hub Credentials**

1. Add Credentials again
2. Select "Username with password"
   - **Username**: Your Docker Hub username
   - **Password**: Your Docker Hub password
   - **ID**: `dockerhub-credentials`
   - **Description**: Docker Hub Access

---

## 📊 **Step 4: Install and Configure SonarQube**

### **4.1 Run SonarQube in Docker**

```powershell
# Run SonarQube container
docker run -d `
  --name sonarqube `
  -p 9000:9000 `
  sonarqube:lts-community

# Wait for SonarQube to start (about 2 minutes)
# Access at: http://localhost:9000
# Default credentials: admin / admin
```

### **4.2 Configure SonarQube**

1. Login to SonarQube: `http://localhost:9000` (admin/admin)
2. Change password when prompted
3. Create new project:
   - Project key: `aceest-fitness`
   - Display name: `ACEest Fitness & Gym`
4. Generate token:
   - Name: `jenkins-token`
   - Copy the token (you'll need it)

### **4.3 Configure SonarQube in Jenkins**

1. Go to: **Manage Jenkins → System**
2. Scroll to **SonarQube servers**
3. Click "Add SonarQube"
   - **Name**: `SonarQube`
   - **Server URL**: `http://localhost:9000`
   - **Server authentication token**: Add new "Secret text" credential
     - Secret: Paste SonarQube token
     - ID: `sonarqube-token`

4. Go to: **Manage Jenkins → Tools**
5. Scroll to **SonarQube Scanner**
6. Click "Add SonarQube Scanner"
   - **Name**: `SonarScanner`
   - Check "Install automatically"

---

## 🐳 **Step 5: Configure Docker**

### **5.1 Install Docker Pipeline Plugin**
Already done in Step 2.2

### **5.2 Test Docker Access**

If Jenkins is running in Docker, ensure it can access Docker daemon:
```powershell
# Verify Docker socket is mounted
docker exec jenkins docker ps
```

---

## ☸️ **Step 6: Configure Kubernetes (Optional - for deployment stage)**

### **6.1 Install Minikube**

```powershell
# Download and install Minikube
choco install minikube

# Start Minikube
minikube start

# Verify
kubectl get nodes
```

### **6.2 Add Kubernetes Config to Jenkins**

1. Get kubeconfig:
```powershell
kubectl config view --raw > C:\jenkins_home\kubeconfig
```

2. In Jenkins: **Manage Jenkins → Credentials → Add Credentials**
   - Kind: "Secret file"
   - File: Upload kubeconfig
   - ID: `kubeconfig`

---

## 🔨 **Step 7: Create Jenkins Pipeline Job**

### **7.1 Create New Job**

1. Click "New Item"
2. Enter name: `ACEest-Fitness-CI-CD`
3. Select "Pipeline"
4. Click "OK"

### **7.2 Configure Pipeline**

#### **General Settings**
- ✅ Check "GitHub project"
- Project url: `https://github.com/SuryaChaturvedula/devops_a2/`

#### **Build Triggers**
- ✅ Check "GitHub hook trigger for GITScm polling"
  - This enables automatic builds on push

#### **Pipeline Section**
- **Definition**: Pipeline script from SCM
- **SCM**: Git
- **Repository URL**: `https://github.com/SuryaChaturvedula/devops_a2.git`
- **Credentials**: Select `github-credentials`
- **Branch Specifier**: `*/main`
- **Script Path**: `Jenkinsfile`

Click "Save"

---

## 🔔 **Step 8: Configure GitHub Webhook**

### **8.1 Setup ngrok (for local Jenkins)**

If Jenkins is running locally, you need ngrok to expose it:

```powershell
# Install ngrok
choco install ngrok

# Expose Jenkins
ngrok http 8080

# Copy the forwarding URL (e.g., https://abc123.ngrok.io)
```

### **8.2 Add Webhook to GitHub**

1. Go to GitHub repository: `https://github.com/SuryaChaturvedula/devops_a2`
2. Settings → Webhooks → Add webhook
3. Configure:
   - **Payload URL**: `http://YOUR_JENKINS_URL/github-webhook/`
     - For ngrok: `https://abc123.ngrok.io/github-webhook/`
     - For public server: `http://your-server:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Which events**: "Just the push event"
   - ✅ Active
4. Click "Add webhook"

---

## 🧪 **Step 9: Test the Pipeline**

### **9.1 Manual Test**

1. Go to Jenkins job: `ACEest-Fitness-CI-CD`
2. Click "Build Now"
3. Watch the build progress
4. Check console output

### **9.2 Automatic Test (via Git push)**

```powershell
cd C:\Users\sriva\Downloads\Devops_A2\Solution

# Make a small change
echo "# Testing Jenkins" >> README.md

# Commit and push
git add README.md
git commit -m "Test Jenkins webhook"
git push origin main

# Jenkins should automatically trigger a build!
```

---

## 📊 **Step 10: View Results**

After pipeline runs:

### **Test Results**
- Click on build number → Test Result

### **Coverage Report**
- Click on build number → Coverage Report

### **SonarQube Analysis**
- Visit: `http://localhost:9000/dashboard?id=aceest-fitness`

### **Docker Images**
```powershell
# List built images
docker images | grep aceest-fitness
```

---

## 🎯 **Pipeline Flow**

```
┌─────────────────────────────────────────────────────────────┐
│  1. Push to GitHub                                          │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│  2. GitHub Webhook triggers Jenkins                         │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Jenkins Pipeline Stages:                                │
│     ├─ Checkout code                                        │
│     ├─ Setup Python environment                             │
│     ├─ Install dependencies                                 │
│     ├─ Lint code (flake8, pylint)                          │
│     ├─ Run unit tests (pytest)                             │
│     ├─ Code quality analysis (SonarQube)                   │
│     ├─ Quality gate check                                  │
│     ├─ Build Docker image                                  │
│     ├─ Test Docker image                                   │
│     ├─ Push to Docker Hub                                  │
│     ├─ Deploy to Kubernetes                                │
│     └─ Post-deployment tests                               │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Success/Failure Notification                            │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚨 **Troubleshooting**

### **Issue: Python not found**
```powershell
# Install Python plugin for Jenkins
# Or configure Python tool in Jenkins → Tools
```

### **Issue: Docker not accessible**
```powershell
# Ensure Docker daemon is running
docker ps

# For Jenkins in Docker, check socket mount
docker inspect jenkins | grep -A 5 Mounts
```

### **Issue: SonarQube connection failed**
```powershell
# Check SonarQube is running
docker ps | grep sonarqube

# Verify SonarQube is accessible
curl http://localhost:9000/api/system/status
```

### **Issue: Kubernetes deployment fails**
```powershell
# Ensure Minikube is running
minikube status

# Check kubectl access
kubectl get nodes
```

---

## 📝 **Next Steps**

1. ✅ Jenkins installed and configured
2. ✅ Pipeline created and tested
3. ✅ Webhook configured for auto-builds
4. ✅ SonarQube integrated
5. ⏭️ Create Docker Hub repository
6. ⏭️ Set up Kubernetes deployment manifests
7. ⏭️ Implement deployment strategies

---

## 🎓 **What This Achieves**

✅ **Automated Testing**: Every push runs tests automatically  
✅ **Quality Gates**: Code must pass quality checks to proceed  
✅ **Continuous Integration**: Code is integrated and validated continuously  
✅ **Automated Deployment**: Successful builds deploy automatically  
✅ **Fast Feedback**: Developers know immediately if something breaks  

---

**Your CI/CD pipeline is now ready!** 🎉

Every time you push code to GitHub, Jenkins will:
1. ✅ Run all tests
2. ✅ Check code quality
3. ✅ Build Docker image
4. ✅ Deploy if everything passes

**No more manual testing before push - Jenkins does it automatically!** 🚀
