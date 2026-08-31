pipeline {
    agent any

    environment {
        PATH = "/usr/local/bin:$PATH"
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '626635402398'
        ECR_FRONTEND = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/tc1-frontend"
        ECR_BACKEND = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/tc1-backend"
    }

    stages {
        stage('Build Frontend Image') {
            steps {
                dir('frontend') {
                    sh 'docker build -t tech-challenge-1-frontend .'
                }
            }
        }

        stage('Build Backend Image') {
            steps {
                dir('backend') {
                    sh 'docker build -t tech-challenge-1-backend .'
                }
            }
        }

        stage('Login to ECR') {
            steps {
                sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
            }
        }

        stage('Push Frontend Image') {
            steps {
                sh "docker tag tech-challenge-1-frontend:latest ${ECR_FRONTEND}:latest"
                sh "docker push ${ECR_FRONTEND}:latest"
            }
        }

        stage('Push Backend Image') {
            steps {
                sh "docker tag tech-challenge-1-backend:latest ${ECR_BACKEND}:latest"
                sh "docker push ${ECR_BACKEND}:latest"
            }
        }

        stage('Deploy to ECS') {
            steps {
                sh "aws ecs update-service --cluster tc1-cluster --service tc1-frontend-service --force-new-deployment --region ${AWS_REGION}"
                sh "aws ecs update-service --cluster tc1-cluster --service tc1-backend-service --force-new-deployment --region ${AWS_REGION}"
            }
        }

        stage('Confirm Success') {
            steps {
                echo 'Both images built, pushed to ECR, and ECS services redeployed successfully.'
            }
        }
    }
}
