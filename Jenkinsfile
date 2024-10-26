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
                    // Define the username and password from the credentials
                    def sshCredentials = 'prod-server' // Replace with your credentials ID
                    def username = 'azureuser' // Your SSH username
                    def password = 'Bachtapro167@' // Your SSH password

                    // Use the password to SSH
                    sh """
                        echo $password | sshpass ssh -o StrictHostKeyChecking=no $username@20.2.217.99 "docker load"
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
