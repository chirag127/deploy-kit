# Changelog

All notable changes documented here. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased] - 2026-08-13
### Changed
- docs: comprehensive README + topics
- fix(ci): pin kubeconform to v0.8.0 to avoid /latest redirect failures

## [Unreleased] - 2026-08-12
### Changed
- chore(deps): add Dependabot config; ignore @chirag127/* path deps
- ci: add auto-issue-triage, release-notes, changelog via chirag127/workflows
- fix(lint): exclude helm templates from yamllint (Go template syntax is not valid YAML)
- feat: complete Kubernetes + Terraform + GitOps reference deployment
