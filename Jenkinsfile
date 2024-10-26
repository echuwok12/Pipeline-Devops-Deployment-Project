pipeline {
    agent any
    environment {
        SONAR_HOST_URL = 'http://20.255.48.4:9000'
        SONARQUBE_SCANNER = 'sonar-scanner' // Corrected to use the command for sonar-scanner
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
                script {
                    withSonarQubeEnv('Sonar Server') { // Use the correct SonarQube server name
                        // Run SonarQube analysis
                        sh "${SONARQUBE_SCANNER} -Dsonar.projectKey=deployment_project -Dsonar.host.url=${SONAR_HOST_URL} -Dsonar.login=<YOUR_SONARQUBE_TOKEN>"
                    }
                }
            }
        }
        stage('Quality Gate') {
            steps {
                script {
                    // Check SonarQube Quality Gate
                    timeout(time: 2, unit: 'MINUTES') {
                        def qualityGate = waitForQualityGate()
                        if (qualityGate.status != 'OK') {
                            error "Quality gate failed: ${qualityGate.status}"
                        }
                    }
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
