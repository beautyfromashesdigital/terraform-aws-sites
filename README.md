# 🚀 Terraform AWS Sites

**Reusable infrastructure & deploy workflow for hosting static Next.js sites on AWS — with automatic S3, CloudFront, ACM, and optional Route 53 DNS.**

---

## 📌 Overview

This project provides:

✅ **Reusable Terraform modules**
✅ **Reusable GitHub Actions workflow**
✅ **One-command deployment** for any static site

You can deploy multiple customer sites on custom domains with:
- Secure S3 bucket with Origin Access Identity (OAI)
- CloudFront CDN with HTTPS (validated by ACM)
- Optional automatic DNS via Route 53 (or manual for other registrars)

---

## 📁 Project structure

```plaintext
terraform-aws-sites/
├── main.tf          # Core Terraform infra
├── variables.tf     # Input variables
├── outputs.tf       # Useful outputs
└── .github/
    └── workflows/
        └── deploy-site.yml   # Reusable GitHub Actions workflow
