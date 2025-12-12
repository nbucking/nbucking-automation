# Nicholas Buckingham Portfolio Website

## Overview

This is a personal portfolio website built with **ASP.NET Core 8** running on **Kubernetes (k3s)** and deployed via **GitLab CI/CD**. The site is served at **nbucking.net** with automatic container image builds and secure TLS/HSTS/CSP headers managed by Traefik.

The website showcases:
- **Home Page**: Introduction and site overview
- **Bio**: Personal and professional background
- **Technical**: Architecture and deployment details explaining how the site was built

## Technology Stack

- **Framework**: ASP.NET Core 8.0 MVC with Bootstrap
- **Container Runtime**: Docker (multi-stage builds)
- **Container Registry**: GitLab Container Registry
- **Orchestration**: Kubernetes (k3s single-node cluster)
- **Ingress**: Traefik with Let's Encrypt TLS
- **CI/CD**: GitLab CI with Kaniko for image builds
- **Security**: OAuth2 Proxy for `/webtop` authentication

## Architecture

```
GitLab Project
    ↓
.gitlab-ci.yml (Kaniko build on every commit)
    ↓
GitLab Container Registry (registry.gitlab.com/nbucking-group/nbucking-project/web)
    ↓
Kubernetes Cluster (k3s)
    ├─ Deployment: nbucking-web (2 replicas)
    ├─ Service: nbucking-web (ClusterIP, port 80)
    └─ Ingress: nbucking-web
        ├─ nbucking.net → portfolio-web service
        ├─ www.nbucking.net → portfolio-web service
        └─ TLS: Let's Encrypt (cert-manager)

Other Routes:
    /webtop → oauth2-proxy → webtop service (authenticated)
```

## How to Change the Website

### Option 1: Local Development + Git Push (Recommended for Code Changes)

1. **Clone and set up**:
   ```bash
   git clone <project-url>
   cd nbucking-project
   dotnet restore
   dotnet build
   ```

2. **Edit content**:
   - **Add/update pages**: Modify views in `src/NbuckingProject.Web/Views/Home/`
   - **Update navigation**: Edit `src/NbuckingProject.Web/Views/Shared/_Layout.cshtml`
   - **Update controller logic**: Modify `src/NbuckingProject.Web/Controllers/HomeController.cs`
   - **Update styles**: Edit `src/NbuckingProject.Web/wwwroot/css/site.css`

3. **Test locally**:
   ```bash
   cd src/NbuckingProject.Web
   dotnet run
   # Visit http://localhost:5000
   ```

4. **Commit and push to main branch**:
   ```bash
   git add .
   git commit -m "Update bio and technical pages"
   git push origin main
   ```

5. **Automatic deployment**:
   - GitLab CI automatically triggers on push to `main`
   - Kaniko builds a Docker image and pushes to GitLab Container Registry
   - Kubernetes pulls the latest image (imagePullPolicy: Always)
   - Rolling deployment updates the site live (zero-downtime)

### Option 2: GitLab Web UI (Quick Text Changes)

1. Navigate to the GitLab project repository
2. Edit files directly in the web UI (e.g., `.cshtml` views)
3. Commit changes to `main` branch
4. Same automatic build and deploy as Option 1

### Option 3: kubectl on the Cluster (For Immediate Testing)

If you have access to the k3s cluster:

```bash
# Manually update the deployment to use a specific image
kubectl set image deployment/nbucking-web \
  web=registry.gitlab.com/nbucking-group/nbucking-project/web:latest \
  -n default

# Watch the rollout
kubectl rollout status deployment/nbucking-web -n default
```

**Note**: This bypasses GitLab CI, so use only for testing. Always commit changes to git.

## Project Structure

```
nbucking-project/
├── .gitlab-ci.yml              # GitLab CI pipeline (Kaniko build)
├── NbuckingProject.sln         # Visual Studio solution
├── README.md                   # This file
├── k8s/                        # Kubernetes manifests
│   ├── deployment.yaml         # Deployment, Service, Ingress specs
│   └── ...
├── src/
│   ├── NbuckingProject.Web/
│   │   ├── Controllers/
│   │   │   └── HomeController.cs
│   │   ├── Views/
│   │   │   ├── Home/
│   │   │   │   ├── Index.cshtml
│   │   │   │   ├── Bio.cshtml
│   │   │   │   └── Technical.cshtml
│   │   │   └── Shared/
│   │   │       └── _Layout.cshtml
│   │   ├── wwwroot/
│   │   │   ├── css/site.css
│   │   │   └── ...
│   │   ├── Dockerfile         # Multi-stage Docker build
│   │   └── NbuckingProject.Web.csproj
│   └── NbuckingProject.Api/
│       └── ...
└── tests/
    └── ...
```

## CI/CD Pipeline

### `.gitlab-ci.yml` Stages

**1. Build Stage** (runs on every commit to `main`):
- Uses Kaniko (container image builder)
- Builds from `src/NbuckingProject.Web/Dockerfile`
- Pushes two tags to GitLab Container Registry:
  - `:latest` (latest build)
  - `:<short-sha>` (commit hash for tracking)

**2. Deploy Stage** (manual trigger):
- Optional: applies Kubernetes manifests
- Currently documented for manual `kubectl apply`

### How the Pipeline Works

1. You push to the `main` branch
2. GitLab CI picks up `.gitlab-ci.yml`
3. Kaniko builds the Docker image from the Dockerfile
4. Image is authenticated and pushed to `registry.gitlab.com/nbucking-group/nbucking-project/web`
5. Kubernetes cluster pulls the image automatically
6. Deployment rolls out the new version (2 replicas, rolling update)
7. Traefik ingress routes traffic to the new pods

### Dockerfile Overview

The Dockerfile uses multi-stage builds:

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
# Build stage: dotnet restore and build

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
# Runtime stage: copy build output and run ASP.NET Core app
```

This keeps the final image lightweight (~200MB) and production-ready.

## Kubernetes Deployment

### Deployment Details

- **Replicas**: 2 (for high availability)
- **Image Pull Policy**: Always (ensures latest image is pulled)
- **Health Checks**:
  - Liveness probe: checks `/` every 10s (restart if fails 3 times)
  - Readiness probe: checks `/` every 5s (remove from load balancer if fails 3 times)
- **Resources**:
  - Requests: 100m CPU, 128Mi RAM
  - Limits: 500m CPU, 512Mi RAM

### Ingress & TLS

- **Hostname**: `nbucking.net` and `www.nbucking.net`
- **TLS Certificate**: Let's Encrypt (managed by cert-manager)
- **Security Headers**: Traefik middlewares enforce HSTS and CSP
- **Ingress Controller**: Traefik (v2.x)

### Image Pull Secret

The cluster uses a Kubernetes secret (`gitlab-registry`) containing GitLab deploy token credentials to pull from the private/internal GitLab Container Registry.

```bash
# If needed, recreate the secret:
kubectl create secret docker-registry gitlab-registry \
  --docker-server=registry.gitlab.com \
  --docker-username=<deploy-token-username> \
  --docker-password=<deploy-token-password> \
  -n default
```

## Environment Variables (Production)

The ASP.NET Core app runs with these environment variables in Kubernetes:

```
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_URLS=http://+:8080
```

These are set in the Deployment spec. Modify them in `k8s/deployment.yaml` if needed.

## Monitoring & Troubleshooting

### Check Deployment Status

```bash
# View deployment status
kubectl get deployment nbucking-web -n default

# View pods
kubectl get pods -l app=nbucking-web -n default

# View logs
kubectl logs -l app=nbucking-web -n default --tail=50

# Describe deployment for events
kubectl describe deployment nbucking-web -n default
```

### Common Issues

- **502 Bad Gateway**: Pod is not healthy (check logs and liveness/readiness probes)
- **ImagePullBackOff**: GitLab Container Registry credentials missing or expired (recreate secret)
- **Pending Pods**: Insufficient cluster resources (check node capacity)

## Future Enhancements

- **Content Management**: Move Bio and Technical sections to Markdown files
- **CI/CD**: Add tag-based releases, SAST scanning, container vulnerability scanning
- **Observability**: Application metrics, Prometheus scraping, structured logging
- **Autoscaling**: HPA (Horizontal Pod Autoscaler) based on CPU/memory
- **Content Versioning**: Archive and version site content

## Security Notes

- No secrets in code (environment variables only)
- TLS enforced at Traefik layer
- HSTS (HTTP Strict Transport Security) enabled
- CSP (Content Security Policy) headers configured
- `/webtop` protected by OAuth2 Proxy (Google authentication)
- ImagePullPolicy: Always ensures only signed GitLab Registry images run

## Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make changes locally and test: `dotnet run`
3. Commit: `git commit -m "Add feature"`
4. Push to GitLab: `git push origin feature/your-feature`
5. Create a Merge Request in GitLab UI
6. Merge to `main` triggers automatic build and deploy

## Contact

Website: https://nbucking.net

---

*Last updated: December 2025*
