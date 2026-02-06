# GitLab CI/CD

> Tự động build, test và deploy Docker images với GitLab CI/CD.

---

## Overview

| Attribute | Value |
|-----------|-------|
| **Free tier** | 400 minutes/month |
| **Config file** | `.gitlab-ci.yml` |
| **Registry** | Built-in Container Registry |
| **Best for** | GitLab projects, self-hosted GitLab |

---

## Basic Build & Push

```yaml
# .gitlab-ci.yml
stages:
  - build
  - deploy

variables:
  IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

build:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $IMAGE_TAG .
    - docker push $IMAGE_TAG
    - docker tag $IMAGE_TAG $CI_REGISTRY_IMAGE:latest
    - docker push $CI_REGISTRY_IMAGE:latest
  only:
    - main
```

---

## Predefined Variables

| Variable | Description |
|----------|-------------|
| `CI_REGISTRY` | `registry.gitlab.com` |
| `CI_REGISTRY_IMAGE` | `registry.gitlab.com/group/project` |
| `CI_REGISTRY_USER` | Username for registry auth |
| `CI_REGISTRY_PASSWORD` | Password/token for auth |
| `CI_COMMIT_SHA` | Full commit SHA |
| `CI_COMMIT_SHORT_SHA` | Short commit SHA (8 chars) |
| `CI_COMMIT_TAG` | Tag name (if tagged) |
| `CI_COMMIT_BRANCH` | Branch name |
| `CI_PROJECT_PATH` | `group/project` |

---

## Full CI/CD Pipeline

```yaml
stages:
  - test
  - build
  - deploy-staging
  - deploy-production

variables:
  DOCKER_TLS_CERTDIR: "/certs"
  IMAGE: $CI_REGISTRY_IMAGE
  IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

# ==================== TEST ====================
test:
  stage: test
  image: node:20-alpine
  cache:
    key: $CI_COMMIT_REF_SLUG
    paths:
      - node_modules/
  script:
    - npm ci
    - npm test
    - npm run lint

# ==================== BUILD ====================
build:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $IMAGE_TAG .
    - docker push $IMAGE_TAG
    # Tag as latest for main branch
    - |
      if [ "$CI_COMMIT_BRANCH" == "main" ]; then
        docker tag $IMAGE_TAG $IMAGE:latest
        docker push $IMAGE:latest
      fi
  only:
    - main
    - develop

# ==================== DEPLOY STAGING ====================
deploy-staging:
  stage: deploy-staging
  image: alpine:latest
  before_script:
    - apk add --no-cache openssh-client
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
    - mkdir -p ~/.ssh
    - chmod 700 ~/.ssh
    - echo "$SSH_KNOWN_HOSTS" >> ~/.ssh/known_hosts
  script:
    - ssh $SSH_USER@$STAGING_SERVER "
        cd ~/myapp &&
        docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY &&
        docker pull $IMAGE_TAG &&
        docker compose up -d --remove-orphans &&
        docker image prune -f
      "
  environment:
    name: staging
    url: https://staging.myapp.com
  only:
    - develop

# ==================== DEPLOY PRODUCTION ====================
deploy-production:
  stage: deploy-production
  image: alpine:latest
  before_script:
    - apk add --no-cache openssh-client
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
    - mkdir -p ~/.ssh
    - chmod 700 ~/.ssh
    - echo "$SSH_KNOWN_HOSTS" >> ~/.ssh/known_hosts
  script:
    - ssh $SSH_USER@$PRODUCTION_SERVER "
        cd ~/myapp &&
        docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY &&
        docker pull $IMAGE_TAG &&
        docker compose up -d --remove-orphans &&
        docker image prune -f
      "
  environment:
    name: production
    url: https://myapp.com
  only:
    - main
  when: manual  # Require manual trigger
```

---

## Multi-stage Docker Build

```yaml
build:
  stage: build
  image: docker:24
  services:
    - docker:24-dind
  variables:
    DOCKER_BUILDKIT: 1
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - >
      docker build
      --build-arg BUILDKIT_INLINE_CACHE=1
      --cache-from $CI_REGISTRY_IMAGE:latest
      -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
      -t $CI_REGISTRY_IMAGE:latest
      .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE:latest
```

---

## Kaniko (No Docker-in-Docker)

```yaml
build:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:v1.19.0-debug
    entrypoint: [""]
  script:
    - /kaniko/executor
      --context $CI_PROJECT_DIR
      --dockerfile $CI_PROJECT_DIR/Dockerfile
      --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
      --destination $CI_REGISTRY_IMAGE:latest
      --cache=true
```

---

## Deploy to Platforms

### Kubernetes

```yaml
deploy:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl config set-cluster k8s --server=$KUBE_SERVER --certificate-authority=$KUBE_CA_CERT
    - kubectl config set-credentials gitlab --token=$KUBE_TOKEN
    - kubectl config set-context default --cluster=k8s --user=gitlab
    - kubectl config use-context default
    - kubectl set image deployment/myapp myapp=$IMAGE_TAG -n production
```

### Docker Compose via SSH

```yaml
deploy:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache openssh-client
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY" | ssh-add -
  script:
    - ssh -o StrictHostKeyChecking=no $SSH_USER@$SERVER "
        cd ~/myapp &&
        docker compose pull &&
        docker compose up -d
      "
```

### Google Cloud Run

```yaml
deploy:
  stage: deploy
  image: google/cloud-sdk:alpine
  script:
    - echo $GCP_SA_KEY | base64 -d > /tmp/key.json
    - gcloud auth activate-service-account --key-file=/tmp/key.json
    - gcloud run deploy myapp
      --image $IMAGE_TAG
      --region asia-southeast1
      --platform managed
      --allow-unauthenticated
```

---

## Environment Variables

### Project Variables

Settings → **CI/CD** → **Variables**

| Type | Description |
|------|-------------|
| **Variable** | Plain text |
| **File** | Creates file with content |
| **Protected** | Only on protected branches |
| **Masked** | Hidden in logs |

### Define in .gitlab-ci.yml

```yaml
variables:
  NODE_ENV: production
  DATABASE_URL: $DATABASE_URL  # From project variables
```

---

## Caching

```yaml
cache:
  key: $CI_COMMIT_REF_SLUG
  paths:
    - node_modules/
    - .npm/

# Or per-job
build:
  cache:
    key:
      files:
        - package-lock.json
    paths:
      - node_modules/
```

---

## Artifacts

```yaml
test:
  script:
    - npm test -- --coverage
  artifacts:
    paths:
      - coverage/
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
    expire_in: 1 week
```

---

## Manual Triggers

```yaml
deploy-production:
  stage: deploy
  script:
    - ./deploy.sh
  when: manual
  allow_failure: false
```

---

## Rules (Advanced Conditions)

```yaml
build:
  rules:
    # Run on main branch
    - if: $CI_COMMIT_BRANCH == "main"

    # Run on tags
    - if: $CI_COMMIT_TAG

    # Run on merge requests
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

    # Run when specific files change
    - changes:
        - src/**/*
        - Dockerfile

    # Skip if commit message contains [skip ci]
    - if: $CI_COMMIT_MESSAGE =~ /\[skip ci\]/
      when: never
```

---

## Include Templates

### From GitLab templates

```yaml
include:
  - template: Docker.gitlab-ci.yml
  - template: Security/SAST.gitlab-ci.yml
```

### From other repos

```yaml
include:
  - project: 'mygroup/ci-templates'
    ref: main
    file: '/docker-build.yml'
```

### From URL

```yaml
include:
  - remote: 'https://example.com/templates/ci.yml'
```

---

## Parallel & Matrix

```yaml
test:
  parallel:
    matrix:
      - NODE_VERSION: ['18', '20', '22']
        DATABASE: ['postgres', 'mysql']
  image: node:$NODE_VERSION
  script:
    - npm test
```

---

## Review Apps

```yaml
review:
  stage: deploy
  script:
    - deploy_review_app.sh
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_COMMIT_REF_SLUG.review.myapp.com
    on_stop: stop_review
  only:
    - merge_requests

stop_review:
  stage: deploy
  script:
    - stop_review_app.sh
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  when: manual
```

---

## Debugging

### Debug locally with gitlab-runner

```bash
# Install gitlab-runner
brew install gitlab-runner

# Run job locally
gitlab-runner exec docker build
```

### Show variables

```yaml
debug:
  script:
    - env | sort
    - echo "Branch: $CI_COMMIT_BRANCH"
    - echo "SHA: $CI_COMMIT_SHA"
```
