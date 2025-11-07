pipeline {
    agent any
    
    environment {
        // Python environment
        PYTHON_VERSION = '3.11'
        // Docker configuration
        DOCKER_IMAGE = 'aceest-fitness'
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
        // SonarQube configuration
        SONARQUBE_ENV = 'SonarQube'
        // Application configuration
        FLASK_APP = 'app.py'
        FLASK_ENV = 'testing'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '📥 Checking out code from Git...'
                checkout scm
                script {
                    // Get version from git tag or commit
                    env.GIT_TAG = sh(returnStdout: true, script: 'git describe --tags --always').trim()
                    echo "Building version: ${env.GIT_TAG}"
                }
            }
        }
        
        stage('Setup Python Environment') {
            steps {
                echo '🐍 Setting up Python environment...'
                sh '''
                    python3 --version
                    pip3 --version
                '''
            }
        }
        
        stage('Install Dependencies') {
            steps {
                echo '📦 Installing Python dependencies...'
                sh '''
                    pip3 install --break-system-packages -r requirements.txt
                '''
            }
        }
        
        stage('Lint Code') {
            steps {
                echo '🔍 Running code linting...'
                sh '''
                    pip3 install --break-system-packages flake8 pylint
                    echo "Running flake8..."
                    flake8 app/ --max-line-length=120 --exclude=__pycache__,*.pyc --exit-zero || true
                    echo "Running pylint..."
                    pylint app/ --exit-zero || true
                '''
            }
        }
        
        stage('Run Unit Tests') {
            steps {
                echo '🧪 Running unit tests with Pytest...'
                sh '''
                    pytest -v --cov=app --cov-report=xml --cov-report=html --cov-report=term
                '''
            }
            post {
                always {
                    // Publish test results
                    junit(allowEmptyResults: true, testResults: '**/test-results.xml')
                    // Publish coverage report
                    publishHTML(target: [
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'htmlcov',
                        reportFiles: 'index.html',
                        reportName: 'Coverage Report'
                    ])
                }
            }
        }
        
        stage('Code Quality Analysis') {
            steps {
                echo '📊 Running SonarQube analysis...'
                script {
                    // SonarQube Scanner
                    withSonarQubeEnv('SonarQube') {
                        sh """
                            sonar-scanner \
                                -Dsonar.projectKey=aceest-fitness \
                                -Dsonar.projectName="ACEest Fitness & Gym" \
                                -Dsonar.projectVersion=\${GIT_TAG} \
                                -Dsonar.sources=app \
                                -Dsonar.tests=tests \
                                -Dsonar.python.coverage.reportPaths=coverage.xml \
                                -Dsonar.python.version=3.11
                        """
                    }
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                echo '🚦 Checking SonarQube Quality Gate...'
                timeout(time: 5, unit: 'MINUTES') {
                    // Don't abort pipeline on first run - just warn
                    script {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            echo "⚠️ Quality Gate failed: ${qg.status}"
                            // Don't fail the build yet - just show warning
                            // Change to 'error' later to enforce quality gates
                        } else {
                            echo "✅ Quality Gate passed!"
                        }
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                script {
                    // Build Docker image with version tag
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${GIT_TAG} .
                        docker tag ${DOCKER_IMAGE}:${GIT_TAG} ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }
        
        stage('Test Docker Image') {
            steps {
                echo '🧪 Testing Docker image...'
                sh """
                    echo "Starting container for testing..."
                    docker run -d --name test-container-\${BUILD_NUMBER} -p 5001:5000 ${DOCKER_IMAGE}:\${GIT_TAG}
                    sleep 10
                    echo "Testing health endpoint..."
                    docker exec test-container-\${BUILD_NUMBER} python3 -c "import urllib.request; response = urllib.request.urlopen('http://localhost:5000/health'); assert response.status == 200; print('✅ Health check passed!')"
                    echo "Stopping test container..."
                    docker stop test-container-\${BUILD_NUMBER}
                    docker rm test-container-\${BUILD_NUMBER}
                """
            }
        }
        
        stage('Push to Docker Hub') {
            when {
                branch 'main'
            }
            steps {
                echo '📤 Pushing Docker image to Docker Hub...'
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", "${DOCKER_CREDENTIALS_ID}") {
                        sh """
                            docker push ${DOCKER_IMAGE}:${GIT_TAG}
                            docker push ${DOCKER_IMAGE}:latest
                        """
                    }
                }
            }
        }
        
        // TODO: Enable after Kubernetes setup
        // stage('Deploy to Kubernetes') {
        //     when {
        //         branch 'main'
        //     }
        //     steps {
        //         echo '☸️ Deploying to Kubernetes...'
        //         sh '''
        //             kubectl set image deployment/aceest-fitness-deployment \
        //                 aceest-fitness=${DOCKER_IMAGE}:${GIT_TAG} \
        //                 --namespace=aceest-fitness
        //             kubectl rollout status deployment/aceest-fitness-deployment \
        //                 --namespace=aceest-fitness
        //         '''
        //     }
        // }
        
        // stage('Post-Deployment Tests') {
        //     when {
        //         branch 'main'
        //     }
        //     steps {
        //         echo '✅ Running post-deployment tests...'
        //         sh '''
        //             # Get the service URL
        //             SERVICE_URL=$(kubectl get service aceest-fitness-service \
        //                 -n aceest-fitness -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        //             
        //             # Test health endpoint
        //             curl -f http://${SERVICE_URL}:5000/health || exit 1
        //             
        //             # Test API endpoints
        //             curl -f http://${SERVICE_URL}:5000/api/workouts || exit 1
        //             
        //             echo "Post-deployment tests passed!"
        //         '''
        //     }
        // }
    }
    
    post {
        always {
            echo '🧹 Cleaning up...'
            sh '''
                # Clean up any test containers
                docker ps -aq -f name=test-container | xargs -r docker rm -f || true
            '''
        }
        success {
            echo '✅ Pipeline completed successfully!'
            echo "Version ${env.GIT_TAG} built and tested successfully"
        }
        failure {
            echo '❌ Pipeline failed!'
            echo "Build failed for version ${env.GIT_TAG}"
        }
    }
}
