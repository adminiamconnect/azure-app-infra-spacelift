# Azure App Infrastructure - Spacelift

This repository contains Terraform infrastructure code to deploy Azure resources
using Spacelift CI/CD integrated with GitHub.

## Structure

- environments/ → Environment-specific configurations
- modules/ → Reusable Terraform modules
- global/ → Provider and version configuration

## Deployment Flow

GitHub → Spacelift → Terraform → Azure

## Authentication

Recommended: Azure OIDC Federated Identity (no client secrets stored).
