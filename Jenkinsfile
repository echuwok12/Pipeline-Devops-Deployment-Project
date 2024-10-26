pipeline {
    agent any
    environment {
        DOCKER_IMAGE = 'test:latest'
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
                sshagent(['prod-server']) {
                    // Save the Docker image and transfer it to the production server
                    sh "docker save ${DOCKER_IMAGE} | ssh azureuser@20.2.217.99 'docker load'"
                    
                    // Stop any existing container and run the new one
                    sh '''
                    ssh azureuser@20.2.217.99 "
                        docker stop old-container || true && docker rm old-container || true &&
                        docker run -d --name new-container -p 80:80 ${DOCKER_IMAGE}"
                    '''
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
