pipeline {
    agent any
    environment {
        SONAR_HOST_URL = 'http://20.255.48.4:9000'
        SONARQUBE_SCANNER = 'SonarScanner' // Name of the SonarQube scanner tool configured in Jenkins
        DOCKER_IMAGE = 'deployment_project:latest'
    }
    stages {
        stage('Checkout') {
            steps {
                // Clone the repository
                git branch: 'test', url: 'https://github.com/echuwok12/Deployment_Project.git', credentialsId: 'github-key'
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarServer') {
                    sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \\
                        -Dsonar.projectKey=DevOpPipeline \\
                        -Dsonar.projectName=DevOpPipeline \\
                        -Dsonar.sources=. \\
                        -Dsonar.sourceEncoding=UTF-8
                    """
                }
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }      
        stage('Quality Gate') {
            steps {
                timeout(time: 1, unit: 'MINUTES') {
                    // Wait for SonarQube Quality Gate
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    // Build Docker image from Dockerfile
                    sh "docker build -t ${DOCKER_IMAGE} ."
                }
            }
        }
        stage('Push Docker Image to Production Server') {
            steps {
                script {
                    sshagent(['prod-server']) {
                        // Save the Docker image and transfer it to the production server
                        sh "docker save ${DOCKER_IMAGE} | ssh user@20.2.217.99 'docker load'"
                        
                        // Stop any existing container and run the new one
                        sh '''
                        ssh user@20.2.217.99 "
                            docker stop old-container || true && docker rm old-container || true &&
                            docker run -d --name new-container -p 80:80 ${DOCKER_IMAGE}"
                        '''
                    }
                }
            }
        }
    }
    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed.'
        }
    }
}
