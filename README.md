# jenkins-jnlp-dind-alpine
￼
[![Docker Stars](https://img.shields.io/docker/stars/mclueppers/jenkins-jnlp-dind-alpine.svg)](https://hub.docker.com/r/mclueppers/jenkins-jnlp-dind-alpine)
[![Docker Pulls](https://img.shields.io/docker/pulls/mclueppers/jenkins-jnlp-dind-alpine.svg)](https://hub.docker.com/r/mclueppers/jenkins-jnlp-dind-alpine)
[![Docker Automated build](https://img.shields.io/docker/automated/mclueppers/jenkins-jnlp-dind-alpine.svg)](https://hub.docker.com/r/mclueppers/jenkins-jnlp-dind-alpine)

A Docker container that has the Docker daemon, Jenkins JNLP slave and docker-compose pre-installed

# Usage

This container can easily replace the official [Jenkins slave image](https://github.com/jenkinsci/docker-jnlp-slave) allowing you to run Docker builds in an isolated manner on top of an AWS ECS cluster.

# Disclaimer

Portions of this repository contain source code from the original Jenkins slave and Docker dind repositories licensed under MIT license.
