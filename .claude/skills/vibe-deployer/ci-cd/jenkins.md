# Jenkins CI/CD

> Self-hosted CI/CD server. Highly customizable, enterprise-ready.

---

## Overview

| Attribute | Value |
|-----------|-------|
| **Cost** | Free (self-hosted) |
| **Config file** | `Jenkinsfile` |
| **Best for** | Enterprise, self-hosted, complex pipelines |

---

## Prerequisites

### Install Jenkins

```bash
# Docker (recommended)
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts

# Get initial password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### Required Plugins

- Docker Pipeline
- Docker plugin
- Pipeline
- Git
- Credentials

---

## Basic Jenkinsfile

```groovy
// Jenkinsfile
pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'myapp'
        DOCKER_TAG = "${BUILD_NUMBER}"
        REGISTRY = 'ghcr.io/username'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                script {
                    docker.build("${REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}")
                }
            }
        }

        stage('Test') {
            steps {
                script {
                    docker.image("${REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}").inside {
                        sh 'npm test'
                    }
                }
            }
        }

        stage('Push') {
            steps {
                script {
                    docker.withRegistry('https://ghcr.io', 'github-credentials') {
                        docker.image("${REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}").push()
                        docker.image("${REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}").push('latest')
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
```

---

## Full CI/CD Pipeline

```groovy
pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'myapp'
        REGISTRY = 'ghcr.io/username'
        DOCKER_CREDENTIALS = 'github-credentials'
        SSH_CREDENTIALS = 'server-ssh-key'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }

    stages {
        // ==================== CHECKOUT ====================
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                }
            }
        }

        // ==================== TEST ====================
        stage('Test') {
            agent {
                docker {
                    image 'node:20-alpine'
                    args '-v $HOME/.npm:/root/.npm'
                }
            }
            steps {
                sh 'npm ci'
                sh 'npm test'
                sh 'npm run lint'
            }
        }

        // ==================== BUILD ====================
        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build(
                        "${REGISTRY}/${DOCKER_IMAGE}:${GIT_COMMIT_SHORT}",
                        "--build-arg NODE_ENV=production ."
                    )
                }
            }
        }

        // ==================== PUSH ====================
        stage('Push to Registry') {
            steps {
                script {
                    docker.withRegistry('https://ghcr.io', DOCKER_CREDENTIALS) {
                        dockerImage.push()
                        dockerImage.push('latest')
                    }
                }
            }
        }

        // ==================== DEPLOY STAGING ====================
        stage('Deploy to Staging') {
            when {
                branch 'develop'
            }
            steps {
                sshagent([SSH_CREDENTIALS]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no deploy@staging.myapp.com '
                            cd ~/myapp &&
                            docker compose pull &&
                            docker compose up -d &&
                            docker image prune -f
                        '
                    """
                }
            }
        }

        // ==================== DEPLOY PRODUCTION ====================
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            input {
                message 'Deploy to production?'
                ok 'Deploy'
            }
            steps {
                sshagent([SSH_CREDENTIALS]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no deploy@production.myapp.com '
                            cd ~/myapp &&
                            docker compose pull &&
                            docker compose up -d &&
                            docker image prune -f
                        '
                    """
                }
            }
        }
    }

    post {
        success {
            slackSend(
                color: 'good',
                message: "Build ${env.BUILD_NUMBER} succeeded: ${env.BUILD_URL}"
            )
        }
        failure {
            slackSend(
                color: 'danger',
                message: "Build ${env.BUILD_NUMBER} failed: ${env.BUILD_URL}"
            )
        }
        always {
            cleanWs()
        }
    }
}
```

---

## Docker Agent

```groovy
pipeline {
    agent {
        docker {
            image 'node:20-alpine'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    stages {
        stage('Build') {
            steps {
                sh 'npm ci'
                sh 'npm run build'
            }
        }
    }
}
```

---

## Multi-branch Pipeline

1. Jenkins → **New Item** → **Multibranch Pipeline**
2. Add source: Git/GitHub
3. Jenkins auto-discovers branches with Jenkinsfile

```groovy
// Branch-specific behavior
stage('Deploy') {
    when {
        anyOf {
            branch 'main'
            branch 'develop'
        }
    }
    steps {
        // Deploy logic
    }
}
```

---

## Credentials Management

### Add Credentials

1. Jenkins → **Manage Jenkins** → **Credentials**
2. Add credentials:
   - Username/Password
   - SSH Private Key
   - Secret text
   - Secret file

### Use in Jenkinsfile

```groovy
// Username/Password
withCredentials([usernamePassword(
    credentialsId: 'docker-credentials',
    usernameVariable: 'DOCKER_USER',
    passwordVariable: 'DOCKER_PASS'
)]) {
    sh 'docker login -u $DOCKER_USER -p $DOCKER_PASS'
}

// SSH Key
sshagent(['server-ssh-key']) {
    sh 'ssh user@server "command"'
}

// Secret text
withCredentials([string(credentialsId: 'api-key', variable: 'API_KEY')]) {
    sh 'curl -H "Authorization: Bearer $API_KEY" ...'
}
```

---

## Parallel Stages

```groovy
stage('Tests') {
    parallel {
        stage('Unit Tests') {
            steps {
                sh 'npm run test:unit'
            }
        }
        stage('Integration Tests') {
            steps {
                sh 'npm run test:integration'
            }
        }
        stage('E2E Tests') {
            steps {
                sh 'npm run test:e2e'
            }
        }
    }
}
```

---

## Matrix Builds

```groovy
matrix {
    axes {
        axis {
            name 'NODE_VERSION'
            values '18', '20', '22'
        }
        axis {
            name 'OS'
            values 'linux', 'macos'
        }
    }
    stages {
        stage('Build') {
            steps {
                echo "Building on ${OS} with Node ${NODE_VERSION}"
            }
        }
    }
}
```

---

## Environment Variables

```groovy
pipeline {
    environment {
        // Static
        NODE_ENV = 'production'

        // From credentials
        DOCKER_PASS = credentials('docker-password')

        // Dynamic
        BUILD_TIME = sh(script: 'date', returnStdout: true).trim()
    }

    stages {
        stage('Build') {
            environment {
                // Stage-specific
                STAGE_VAR = 'value'
            }
            steps {
                sh 'echo $NODE_ENV'
            }
        }
    }
}
```

---

## Artifacts

```groovy
stage('Build') {
    steps {
        sh 'npm run build'
    }
    post {
        success {
            archiveArtifacts artifacts: 'dist/**/*', fingerprint: true
        }
    }
}

stage('Deploy') {
    steps {
        // Use artifacts from previous stage
        copyArtifacts(
            projectName: env.JOB_NAME,
            selector: specific(env.BUILD_NUMBER)
        )
    }
}
```

---

## Declarative vs Scripted

### Declarative (Recommended)

```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'npm run build'
            }
        }
    }
}
```

### Scripted

```groovy
node {
    stage('Build') {
        sh 'npm run build'
    }
}
```

---

## Shared Libraries

### Create library

```groovy
// vars/dockerBuild.groovy
def call(String imageName) {
    sh "docker build -t ${imageName} ."
}
```

### Use in Jenkinsfile

```groovy
@Library('my-shared-library') _

pipeline {
    stages {
        stage('Build') {
            steps {
                dockerBuild('myapp:latest')
            }
        }
    }
}
```

---

## Triggers

```groovy
pipeline {
    triggers {
        // Poll SCM
        pollSCM('H/5 * * * *')

        // Cron
        cron('H 2 * * *')

        // GitHub webhook
        githubPush()

        // Upstream job
        upstream(upstreamProjects: 'other-job', threshold: hudson.model.Result.SUCCESS)
    }
}
```

---

## Notifications

### Slack

```groovy
post {
    success {
        slackSend(
            channel: '#deployments',
            color: 'good',
            message: "Deployed: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        )
    }
}
```

### Email

```groovy
post {
    failure {
        emailext(
            subject: "Build Failed: ${env.JOB_NAME}",
            body: "Check: ${env.BUILD_URL}",
            to: 'team@company.com'
        )
    }
}
```

---

## Blue Ocean UI

Modern Jenkins UI:

1. Install **Blue Ocean** plugin
2. Access at: `http://jenkins:8080/blue`

---

## Quick Reference

```groovy
// === COMMON STEPS ===
sh 'command'                    // Shell command
bat 'command'                   // Windows command
checkout scm                    // Git checkout
git branch: 'main', url: '...'  // Git clone

// === DOCKER ===
docker.build('image:tag')
docker.image('image').push()
docker.withRegistry('url', 'creds') { }

// === FILES ===
writeFile file: 'name', text: 'content'
readFile 'filename'
fileExists 'filename'

// === INPUT ===
input message: 'Continue?'
input message: 'Deploy?', ok: 'Yes', parameters: [...]

// === CONDITIONS ===
when { branch 'main' }
when { expression { return true } }
when { changeset 'src/**' }
```
