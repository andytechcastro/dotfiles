Infrastructure standards:
- All IaC must be versioned and reviewed via PR
- Use modules, never duplicate resource blocks
- Tag all resources with project, environment, owner
- State files must be remote (GCS/S3) with locking
- CI/CD must run plan before apply, require approval
- Rollback strategy documented for every change
