pipeline {
    agent any

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

        stage('Confirm Success') {
            steps {
                echo 'Both frontend and backend Docker images built successfully.'
            }
        }
    }
}

