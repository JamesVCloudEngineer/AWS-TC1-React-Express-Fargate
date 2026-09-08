# AWS TC1: React/Express App on ECS Fargate with Jenkins CI/CD

A full-stack web application deployed on AWS ECS Fargate, with a Jenkins pipeline handling continuous integration and deployment. The frontend is built in React, the backend in Express, and traffic is routed through an Application Load Balancer to containerized services running behind the scenes.

## Live Demo

The application is deployed and reachable through the ALB:

http://tc1-alb-1440184846.us-east-1.elb.amazonaws.com

On load, the frontend fetches a unique identifier from the backend and displays it, confirming the full request path works end to end: browser to ALB to frontend container to backend container and back.

## Architecture

- Frontend: React app, containerized with Docker, served via ECS Fargate
- Backend: Express API, containerized with Docker, served via ECS Fargate
- Load Balancing: Application Load Balancer routes traffic to frontend and backend target groups
- Container Registry: Amazon ECR stores frontend and backend images
- Orchestration: ECS Fargate cluster runs both services, with autoscaling policies attached
- CI/CD: Jenkins, running on a dedicated EC2 instance, builds Docker images, pushes to ECR, and triggers ECS service redeployments
- Infrastructure as Code: All AWS resources (VPC, subnets, security groups, ALB, ECS, IAM roles, Jenkins EC2) are provisioned via Terraform

## Tech Stack

- React 19
- Express (Node.js)
- Docker
- AWS ECS Fargate
- AWS ECR
- AWS Application Load Balancer
- Jenkins
- Terraform

## CI/CD Pipeline

The Jenkins pipeline runs on a dedicated EC2 instance and performs the following on each build:

1. Pulls the latest code from GitHub
2. Builds Docker images for both frontend and backend
3. Pushes images to their respective ECR repositories
4. Triggers a new ECS service deployment so the running tasks pick up the latest images

## Deployment

All infrastructure is defined in the terraform directory. To provision from scratch, run terraform init, then terraform plan, then terraform apply from inside that folder.

This provisions the VPC, subnets, security groups, ALB, ECS cluster and services, ECR repositories, IAM roles, and the Jenkins EC2 instance, with Jenkins auto-installed via user data.

Once the Jenkins EC2 instance is up, visit it on port 8080 to access the Jenkins UI and configure the pipeline job pointing at this repository's Jenkinsfile.

## Infrastructure Resilience

The Jenkins EC2 instance's boot script provisions a 2GB swap file and resizes /tmp to 2GB automatically on launch. This was added after a production incident where the undersized instance ran out of memory mid-build, and ensures any future instance replacement comes up pre-hardened against the same failure.

## Troubleshooting Notes

Memory exhaustion during builds: The Jenkins EC2 instance, a t2.micro with roughly 950MB of RAM, froze mid-build while compiling the React production bundle. Diagnosed via CloudWatch as a sustained CPU spike to 100 percent. Resolved by adding a 2GB swap file and resizing /tmp, both now baked permanently into the Terraform user data script so they persist across any future reboot or instance replacement.

Blank page after successful build: A build would complete successfully, but the deployed page loaded blank with a browser console error reading "o.render is not a function." Root cause was a React version mismatch, the app had been upgraded to React 19, but index.js still used the React 17-era ReactDOM.render API. Fixed by switching to ReactDOM.createRoot().render(), the React 18-plus pattern.

## Cost Considerations

- ECS Fargate tasks and the Jenkins EC2 instance are the primary ongoing costs
- The Jenkins EC2 instance uses a t2.micro to minimize cost, with the swap file mitigating its memory constraints rather than upsizing the instance
- Infrastructure can be torn down cleanly via terraform destroy when not actively in use
