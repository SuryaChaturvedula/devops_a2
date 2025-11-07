# SonarQube Integration Setup

## 🎯 Quick Setup (5 minutes)

### Step 1: Configure SonarQube Server

1. **Open SonarQube**: http://localhost:9000
2. **Login**: 
   - Username: `admin`
   - Password: `admin`
   - (You'll be prompted to change password - set it to something you'll remember)

3. **Create a Project Token**:
   - Click **Administration** (top menu) → **Security** → **Users**
   - Click on **admin** → **Tokens**
   - Generate new token:
     - Name: `jenkins-token`
     - Type: `Project Analysis Token` (or `Global Analysis Token`)
     - Click **Generate**
   - **⚠️ COPY THE TOKEN IMMEDIATELY** (you can't see it again!)
   - Example: `squ_1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r`

### Step 2: Configure Jenkins

1. **Add SonarQube Server in Jenkins**:
   - Go to: http://localhost:8080
   - **Manage Jenkins** → **System**
   - Scroll to **SonarQube servers** section
   - Click **Add SonarQube**
   - Fill in:
     - **Name**: `SonarQube` (exactly this - it's in Jenkinsfile)
     - **Server URL**: `http://sonarqube:9000` (use container name, not localhost!)
     - **Server authentication token**: Click **Add** → **Jenkins**
       - Kind: `Secret text`
       - Secret: Paste your SonarQube token
       - ID: `sonarqube-token`
       - Description: `SonarQube Authentication Token`
       - Click **Add**
     - Select the credential you just created
   - Click **Save**

2. **Configure SonarQube Scanner Tool**:
   - **Manage Jenkins** → **Tools**
   - Scroll to **SonarQube Scanner** section
   - Click **Add SonarQube Scanner**
   - Fill in:
     - **Name**: `SonarScanner` (or any name)
     - **SONAR_RUNNER_HOME**: `/opt/sonar-scanner`
   - Click **Save**

### Step 3: Create SonarQube Project

1. **Back in SonarQube** (http://localhost:9000):
   - Click **Create Project** → **Manually**
   - **Project key**: `aceest-fitness`
   - **Display name**: `ACEest Fitness & Gym`
   - Click **Set Up**
   - Choose **Locally**
   - Use existing token or generate new one
   - Click **Continue**

### Step 4: Enable SonarQube in Jenkinsfile

The SonarQube stages are already in your Jenkinsfile but commented out. I'll uncomment them for you!

---

## 🔍 What SonarQube Will Analyze

Once enabled, every build will check:

✅ **Code Quality**:
- Code smells (bad practices)
- Code duplication
- Complexity (cyclomatic complexity > 10)
- Maintainability rating (A-E)

✅ **Security**:
- Security hotspots
- Vulnerabilities (SQL injection, XSS, etc.)
- Security rating (A-E)

✅ **Reliability**:
- Bugs in code
- Type errors
- Reliability rating (A-E)

✅ **Coverage**:
- Line coverage (currently 73%)
- Branch coverage
- Unit test count

✅ **Quality Gates**:
- Enforces minimum standards
- Can fail builds if standards not met
- Default: Coverage > 80%, No critical issues

---

## 📊 SonarQube Dashboard

After first scan, you'll see:

```
Overall Code:            C Rating
Reliability:             A Rating (0 bugs)
Security:                A Rating (0 vulnerabilities)
Maintainability:         C Rating (30 code smells)
Coverage:                73.0%
Duplications:            0.0%
Lines of Code:           228
```

---

## 🚨 Common Issues & Fixes

### Issue 1: "SonarQube server not found"
**Fix**: Use `http://sonarqube:9000` (container name), NOT `http://localhost:9000`

### Issue 2: "Unauthorized - Invalid token"
**Fix**: Regenerate token in SonarQube and update Jenkins credential

### Issue 3: "Project not found"
**Fix**: Create project in SonarQube with key `aceest-fitness`

### Issue 4: "Quality Gate failed"
**Fix**: This is GOOD - it's working! Fix the issues or adjust quality gate thresholds

---

## 🎯 Next Steps After Setup

1. ✅ Run a build - SonarQube will analyze your code
2. 📊 Check the dashboard at http://localhost:9000
3. 🔧 Fix issues highlighted by SonarQube
4. ✅ Re-run build - see improvements!

---

## 💡 Pro Tips

- **Don't fail builds on first scan**: Use `abortPipeline: false` initially
- **Adjust quality gates**: Go to **Quality Gates** in SonarQube → Customize
- **Exclude test files**: Already configured in `sonar-project.properties`
- **Focus on new code**: SonarQube can focus on changes since last analysis

Ready? Let me know when you've completed Steps 1-3! 🚀
