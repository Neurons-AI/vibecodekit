# Bitbucket Pipelines

> CI/CD tích hợp trong Bitbucket. Build, test và deploy Docker images.

---

## Overview

| Attribute | Value |
|-----------|-------|
| **Free tier** | 50 minutes/month |
| **Config file** | `bitbucket-pipelines.yml` |
| **Best for** | Bitbucket/Atlassian teams |

---

## Basic Build & Push

```yaml
# bitbucket-pipelines.yml
image: atlassian/default-image:4

pipelines:
  default:
    - step:
        name: Build and Push Docker Image
        services:
          - docker
        script:
          - docker build -t myapp:$BITBUCKET_COMMIT .
          - docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
          - docker tag myapp:$BITBUCKET_COMMIT $DOCKER_USERNAME/myapp:latest
          - docker push $DOCKER_USERNAME/myapp:latest

definitions:
  services:
    docker:
      memory: 2048
```

---

## Predefined Variables

| Variable | Description |
|----------|-------------|
| `BITBUCKET_COMMIT` | Full commit hash |
| `BITBUCKET_BRANCH` | Branch name |
| `BITBUCKET_TAG` | Tag name |
| `BITBUCKET_REPO_SLUG` | Repository name |
| `BITBUCKET_WORKSPACE` | Workspace name |
| `BITBUCKET_BUILD_NUMBER` | Build number |

---

## Full CI/CD Pipeline

```yaml
image: node:20

pipelines:
  # ==================== DEFAULT (all branches) ====================
  default:
    - step:
        name: Test
        caches:
          - node
        script:
          - npm ci
          - npm test
          - npm run lint

  # ==================== BRANCH-SPECIFIC ====================
  branches:
    develop:
      - step:
          name: Test
          caches:
            - node
          script:
            - npm ci
            - npm test

      - step:
          name: Build Docker Image
          services:
            - docker
          script:
            - docker build -t $DOCKER_REGISTRY/myapp:$BITBUCKET_COMMIT .
            - docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD $DOCKER_REGISTRY
            - docker push $DOCKER_REGISTRY/myapp:$BITBUCKET_COMMIT

      - step:
          name: Deploy to Staging
          deployment: staging
          script:
            - pipe: atlassian/ssh-run:0.4.1
              variables:
                SSH_USER: $SSH_USER
                SERVER: $STAGING_SERVER
                COMMAND: >
                  cd ~/myapp &&
                  docker pull $DOCKER_REGISTRY/myapp:$BITBUCKET_COMMIT &&
                  docker compose up -d

    main:
      - step:
          name: Test
          caches:
            - node
          script:
            - npm ci
            - npm test

      - step:
          name: Build Docker Image
          services:
            - docker
          script:
            - docker build -t $DOCKER_REGISTRY/myapp:$BITBUCKET_COMMIT .
            - docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD $DOCKER_REGISTRY
            - docker push $DOCKER_REGISTRY/myapp:$BITBUCKET_COMMIT
            - docker tag $DOCKER_REGISTRY/myapp:$BITBUCKET_COMMIT $DOCKER_REGISTRY/myapp:latest
            - docker push $DOCKER_REGISTRY/myapp:latest

      - step:
          name: Deploy to Production
          deployment: production
          trigger: manual
          script:
            - pipe: atlassian/ssh-run:0.4.1
              variables:
                SSH_USER: $SSH_USER
                SERVER: $PRODUCTION_SERVER
                COMMAND: >
                  cd ~/myapp &&
                  docker pull $DOCKER_REGISTRY/myapp:latest &&
                  docker compose up -d

definitions:
  services:
    docker:
      memory: 2048
```

---

## Push to Different Registries

### Docker Hub

```yaml
- step:
    name: Push to Docker Hub
    services:
      - docker
    script:
      - docker login -u $DOCKERHUB_USERNAME -p $DOCKERHUB_PASSWORD
      - docker build -t $DOCKERHUB_USERNAME/myapp:latest .
      - docker push $DOCKERHUB_USERNAME/myapp:latest
```

### AWS ECR

```yaml
- step:
    name: Push to AWS ECR
    services:
      - docker
    script:
      - pipe: atlassian/aws-ecr-push-image:2.0.0
        variables:
          AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
          AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
          AWS_DEFAULT_REGION: ap-southeast-1
          IMAGE_NAME: myapp
          TAGS: 'latest $BITBUCKET_COMMIT'
```

### Google Artifact Registry

```yaml
- step:
    name: Push to GAR
    services:
      - docker
    script:
      - echo $GCLOUD_API_KEYFILE | base64 -d > /tmp/key.json
      - cat /tmp/key.json | docker login -u _json_key --password-stdin https://asia-southeast1-docker.pkg.dev
      - docker build -t asia-southeast1-docker.pkg.dev/$GCLOUD_PROJECT/myrepo/myapp:$BITBUCKET_COMMIT .
      - docker push asia-southeast1-docker.pkg.dev/$GCLOUD_PROJECT/myrepo/myapp:$BITBUCKET_COMMIT
```

---

## Deploy with Pipes

### SSH Deployment

```yaml
- step:
    name: Deploy via SSH
    script:
      - pipe: atlassian/ssh-run:0.4.1
        variables:
          SSH_USER: 'deploy'
          SERVER: 'myserver.com'
          SSH_KEY: $SSH_PRIVATE_KEY
          COMMAND: 'cd ~/myapp && docker compose pull && docker compose up -d'
```

### AWS ECS

```yaml
- step:
    name: Deploy to ECS
    script:
      - pipe: atlassian/aws-ecs-deploy:1.6.0
        variables:
          AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
          AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
          AWS_DEFAULT_REGION: 'ap-southeast-1'
          CLUSTER_NAME: 'myapp-cluster'
          SERVICE_NAME: 'myapp-service'
          TASK_DEFINITION: 'task-definition.json'
```

### Kubernetes

```yaml
- step:
    name: Deploy to Kubernetes
    script:
      - pipe: atlassian/kubectl-run:3.0.0
        variables:
          KUBE_CONFIG: $KUBE_CONFIG
          KUBECTL_COMMAND: 'set image deployment/myapp myapp=$DOCKER_REGISTRY/myapp:$BITBUCKET_COMMIT'
```

---

## Repository Variables

### Add Variables

1. Repository → **Settings** → **Repository variables**
2. Add key-value pairs
3. Check **Secured** for secrets

### Common Variables

| Variable | Description |
|----------|-------------|
| `DOCKER_USERNAME` | Docker registry username |
| `DOCKER_PASSWORD` | Docker registry password |
| `DOCKER_REGISTRY` | Registry URL |
| `SSH_PRIVATE_KEY` | SSH key for deployment |
| `AWS_ACCESS_KEY_ID` | AWS credentials |
| `AWS_SECRET_ACCESS_KEY` | AWS credentials |

---

## Deployment Environments

```yaml
- step:
    name: Deploy
    deployment: production  # staging, test, production
    trigger: manual
    script:
      - ./deploy.sh
```

Configure environments: Repository → **Settings** → **Deployments**

---

## Caching

```yaml
definitions:
  caches:
    npm: ~/.npm
    docker: ~/.docker

pipelines:
  default:
    - step:
        caches:
          - npm
          - docker
        script:
          - npm ci
          - docker build .
```

---

## Artifacts

```yaml
- step:
    name: Build
    script:
      - npm run build
    artifacts:
      - dist/**

- step:
    name: Deploy
    script:
      - ls dist/  # Artifacts from previous step available
```

---

## Parallel Steps

```yaml
pipelines:
  default:
    - parallel:
        - step:
            name: Test Unit
            script:
              - npm run test:unit

        - step:
            name: Test Integration
            script:
              - npm run test:integration

        - step:
            name: Lint
            script:
              - npm run lint
```

---

## Conditions

```yaml
pipelines:
  default:
    - step:
        name: Build
        script:
          - npm run build
        condition:
          changesets:
            includePaths:
              - "src/**"
              - "package.json"
```

---

## Tags

```yaml
pipelines:
  tags:
    'v*':
      - step:
          name: Build Release
          script:
            - docker build -t myapp:$BITBUCKET_TAG .
            - docker push myapp:$BITBUCKET_TAG
```

---

## Custom Docker Image

```yaml
image:
  name: myregistry.com/custom-image:latest
  username: $REGISTRY_USER
  password: $REGISTRY_PASSWORD

pipelines:
  default:
    - step:
        script:
          - custom-command
```

---

## Memory & Size

```yaml
- step:
    name: Build Large Project
    size: 2x  # Double memory (8GB)
    services:
      - docker
    script:
      - docker build .

definitions:
  services:
    docker:
      memory: 4096  # 4GB for Docker
```

---

## Pull Requests

```yaml
pipelines:
  pull-requests:
    '**':
      - step:
          name: PR Checks
          script:
            - npm ci
            - npm test
            - npm run lint
```

---

## Debug

```yaml
- step:
    name: Debug
    script:
      - printenv | sort
      - echo "Commit: $BITBUCKET_COMMIT"
      - echo "Branch: $BITBUCKET_BRANCH"
```

---

## Common Pipes

| Pipe | Usage |
|------|-------|
| `atlassian/ssh-run` | Run commands via SSH |
| `atlassian/aws-ecr-push-image` | Push to AWS ECR |
| `atlassian/aws-ecs-deploy` | Deploy to ECS |
| `atlassian/kubectl-run` | Run kubectl commands |
| `atlassian/slack-notify` | Send Slack notifications |
| `atlassian/scp-deploy` | Copy files via SCP |

Browse more: https://bitbucket.org/atlassian/workspace/pipelines
