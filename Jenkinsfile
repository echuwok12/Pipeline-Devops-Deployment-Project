pipeline {
    agent any
    environment {
        DOCKER_IMAGE = 'deployment_project:latest'
    }
    
    stages {
        stage('Checkout') {
            steps {
                // Clone the repository
                git branch: 'test', url: 'https://github.com/echuwok12/Deployment_Project.git', credentialsId: 'github-key'
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
                    // Use the configured "Production Server" in the Server group center
                    sshCommand remote: 'Production Server', command: """
                        docker load < <(docker save ${DOCKER_IMAGE}) &&
                        docker stop old-container || true && docker rm old-container || true &&
                        docker run -d --name new-container -p 80:80 ${DOCKER_IMAGE}
                    """
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
        always {
            // Clean workspace after build
            cleanWs()
        }
    }
}
