# Switch Jenkins to Use Jenkinsfile from GitHub (SCM)

## ✅ Why This Is Better for Your Assignment

1. **Professional & Industry Standard** - This is how real CI/CD pipelines work
2. **Evaluator Can See Everything** - Your Jenkinsfile is visible in your GitHub repo
3. **Version Controlled** - All pipeline changes are tracked in Git
4. **No Manual Copying** - Jenkins automatically fetches the latest Jenkinsfile from GitHub

---

## 🔧 How to Switch (2 minutes)

### Step 1: Open Jenkins Job Configuration
1. Go to Jenkins: http://localhost:8080
2. Click on your job: **ACEest-Fitness-CI-CD**
3. Click **Configure** (left sidebar)

### Step 2: Change Pipeline Definition
1. Scroll down to the **Pipeline** section
2. Change **Definition** dropdown from:
   - ❌ `Pipeline script` 
   - ✅ TO: `Pipeline script from SCM`

### Step 3: Configure SCM Settings
Fill in these settings:

- **SCM**: `Git`
- **Repository URL**: `https://github.com/SuryaChaturvedula/devops_a2.git`
- **Credentials**: Select `github-credentials` (the one you created earlier)
- **Branch Specifier**: `*/main`
- **Script Path**: `Jenkinsfile` (default - this is the file name in your repo)

### Step 4: Advanced Settings (Optional but Recommended)
Click **Additional Behaviours** → Add → **Clean before checkout**
- This ensures a fresh clone every time

### Step 5: Save and Test
1. Click **Save** at the bottom
2. Click **Build Now**
3. Watch the console output

---

## 🎯 What Changed in the Jenkinsfile?

I fixed these issues in your `Jenkinsfile`:

✅ Changed `python` → `python3` (Jenkins container uses python3)
✅ Changed `pip` → `pip3` 
✅ Added `--break-system-packages` flag for Python 3.13
✅ Fixed health check to use Python's urllib instead of curl
✅ Added `BUILD_NUMBER` to test container names to avoid conflicts
✅ Changed sleep from 5 to 10 seconds for container startup

---

## 📊 What the Evaluator Will See

When your evaluator checks your GitHub repo, they'll see:

```
devops_a2/
├── Jenkinsfile              ← Complete CI/CD pipeline definition
├── Dockerfile               ← Application container setup
├── Dockerfile.jenkins       ← Custom Jenkins image with Python+Docker
├── sonar-project.properties ← SonarQube configuration
├── requirements.txt         ← Python dependencies
├── pytest.ini              ← Test configuration
├── app/                    ← Application code
├── tests/                  ← 40 unit tests
└── README.md              ← Project documentation
```

Everything is transparent and version-controlled! 🎉

---

## 🆚 Comparison: SCM vs Embedded

| Feature | Pipeline from SCM ✅ | Embedded Script ❌ |
|---------|---------------------|-------------------|
| **Visible in GitHub** | ✅ Yes | ❌ No |
| **Version controlled** | ✅ Yes | ❌ No |
| **Easy for evaluator** | ✅ Yes | ❌ No (needs Jenkins access) |
| **Industry standard** | ✅ Yes | ❌ No |
| **Auto-updates** | ✅ Yes (on webhook) | ❌ Manual copy needed |
| **Proper GitOps** | ✅ Yes | ❌ No |

---

## 🐛 If You Get Errors

### Error: "fatal: not in a git directory"
**Solution**: Don't worry - this was the old issue. The new approach uses `checkout scm` which Jenkins handles automatically.

### Error: "externally-managed-environment"
**Solution**: Already fixed with `--break-system-packages` flag

### Error: "curl: command not found"
**Solution**: Already fixed - using Python's urllib instead

---

## 🚀 Next Steps After Switching

Once the SCM pipeline works, you can:

1. **Add SonarQube** - Uncomment the SonarQube stages in Jenkinsfile
2. **Add Docker Hub Push** - Uncomment the push stage
3. **Set up GitHub Webhook** - Auto-trigger builds on git push
4. **Add Kubernetes Deployment** - Deploy to Minikube

All changes will be in your Jenkinsfile in Git! 🎯

---

## 💡 Pro Tip

From now on, to update your pipeline:
1. Edit `Jenkinsfile` locally
2. `git commit -m "Update pipeline"`
3. `git push`
4. Jenkins will use the new version automatically!

No more copying/pasting! 🎉
