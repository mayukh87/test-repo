# Bitbucket CI/CD Pipeline Workflow

This repository uses a two-stage CI/CD pipeline approach with separate workflows for Continuous Integration (CI) and Continuous Deployment (CD).

## Pipeline Overview

### 🔄 CI Pipeline (Automatic)
- **Trigger**: Automatic on push to `main`, `develop`, `feature/**`, `hotfix/**` branches
- **Purpose**: Code quality checks and validation
- **Tools**: Ruff (linting), UV (dependency management)
- **Duration**: ~2-5 minutes

### 🚀 CD Pipeline (Manual)
- **Trigger**: Manual execution with environment selection
- **Purpose**: Infrastructure deployment and terraform workspace management
- **Tools**: AWS CLI, Terraform, TFLint, TFSec
- **Duration**: ~5-10 minutes

## Workflow Steps

### 1. CI Pipeline (Automatic Execution)

When you push code to any of the monitored branches, the CI pipeline automatically:

1. **Sets up Python 3.11 environment**
2. **Installs UV package manager**
   ```bash
   pip install uv
   ```
3. **Installs Ruff linter**
   ```bash
   uv tool install ruff
   ```
4. **Runs code quality checks**:
   - Ruff linting: `ruff check . --output-format=github`
   - Ruff formatting: `ruff format --check .`
   - UV dependency validation: `uv sync --check`

**Triggers on**:
- Push to `main` branch
- Push to `develop` branch  
- Push to any `feature/**` branch
- Push to any `hotfix/**` branch
- Pull requests to any branch

### 2. CD Pipeline (Manual Execution)

After CI passes, you can manually trigger the CD pipeline:

1. **Navigate to Bitbucket Pipelines**
2. **Click "Run pipeline"**
3. **Select "Custom: deploy-to-environment"**
4. **Choose target environment**:
   - `dev` (default)
   - `qa`
   - `prod`
5. **Click "Run"**

The CD pipeline will:
1. **Install deployment tools** (AWS CLI, Terraform, TFLint, TFSec)
2. **Configure AWS credentials** from repository variables
3. **Run infrastructure validation**
4. **Select/create terraform workspace** based on chosen environment
5. **Execute deployment** to the selected environment

## Environment Variables Required

Configure these in Bitbucket Repository Settings → Repository variables:

### AWS Credentials
- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
- `AWS_DEFAULT_REGION`: Default AWS region (e.g., `us-east-1`)

## Branch Strategy

### Automatic CI Triggers
```
main/develop/feature/*/hotfix/* → CI Pipeline
                                      ↓
                               Code Quality Checks
                                      ↓
                                  Pass/Fail
```

### Manual CD Trigger
```
Manual Trigger → Environment Selection → CD Pipeline
                      ↓                      ↓
                 (dev/qa/prod)         Infrastructure Deployment
```

## Usage Examples

### Feature Development
1. Create feature branch: `feature/user-authentication`
2. Push code → CI automatically runs
3. Create PR → CI runs again
4. After merge to main → CI runs on main
5. Manually trigger CD to deploy to `dev` environment

### Hotfix Deployment
1. Create hotfix branch: `hotfix/security-patch`
2. Push code → CI automatically runs
3. After merge → Manually trigger CD to deploy to `prod`

### Environment Promotion
1. Deploy to `dev` → Test
2. Deploy to `qa` → QA validation
3. Deploy to `prod` → Production release

## Pipeline Status

- ✅ **CI Success**: Code quality checks passed
- ❌ **CI Failure**: Fix linting/formatting issues
- 🚀 **CD Success**: Deployment completed
- ⚠️ **CD Failure**: Check infrastructure/terraform issues

## Monitoring

- **CI Results**: Check ruff output for code quality issues
- **CD Results**: Monitor terraform workspace and AWS resource creation
- **Artifacts**: CI pipeline generates `ruff-report.json` for detailed analysis

## Best Practices

1. **Always wait for CI to pass** before triggering CD
2. **Test in dev environment first** before promoting to qa/prod
3. **Use meaningful commit messages** for better pipeline tracking
4. **Monitor pipeline notifications** in Bitbucket
5. **Review terraform plans** before applying changes

## Troubleshooting

### CI Pipeline Issues
- **Ruff linting failures**: Fix code formatting and style issues
- **UV dependency issues**: Update or fix dependency conflicts
- **Installation failures**: Check Python environment and package availability

### CD Pipeline Issues
- **AWS credential errors**: Verify repository variables are set correctly
- **Terraform workspace issues**: Check workspace permissions and state backend
- **Infrastructure failures**: Review terraform configuration and AWS permissions

## Pipeline Configuration

The complete pipeline configuration is in `bitbucket-pipelines.yml` with:
- **Reusable step definitions** for maintainability
- **Caching** for faster builds
- **Clear logging** for debugging
- **Environment-specific deployments**