# microsite-ops

This repository contains the yaml files to depoly the docker images built in `ricardojfc/microsite`.
Each time a PR is merged into main on the repository `ricardojfc/microsite`, a PR is created here to update the Kubernetes configuration files (yaml).

The image tags within these manifests are replaced with the short commit hash originating from the application repository commit (`ricardojfc/microsite`).

The generated PR serves as a review mechanism simulating a corporate Change Advisory Board (CAB) approval loop.
Upon validation and approval of the configuration drift, the operations repository merges the manifest updates into its main branch.

Deployment to the target Kubernetes cluster is manually triggered utilizing the shell script located in `apps/microsite/environments/production`.
