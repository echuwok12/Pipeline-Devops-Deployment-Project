pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'test:latest'
        PROD_SERVER = 'azureuser@20.2.217.99'
    }
    
    stages {
        stage('Checkout') {
            steps {
                // Clean workspace before checkout
                cleanWs()
                // Clone the repository
                git branch: 'test', 
                    url: 'https://github.com/echuwok12/Deployment_Project.git', 
                    credentialsId: 'github-key'
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
                    withCredentials([sshUserPrivateKey(credentialsId: 'prod-server', keyFileVariable: 'SSH_KEY')]) {
                        // Save and transfer Docker image
                        sh """
                            docker save ${DOCKER_IMAGE} | ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${PROD_SERVER} 'docker load'
                        """
                        
                        // Stop existing container, remove it, and run new one
                        sh """
                            ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${PROD_SERVER} '
                                # Stop and remove existing container if it exists
                                docker stop new-container || true
                                docker rm new-container || true
                                
                                # Remove old image to free up space
                                docker rmi ${DOCKER_IMAGE} || true
                                
                                # Run new container
                                docker run -d \
                                    --name new-container \
                                    --restart unless-stopped \
                                    -p 80:80 \
                                    ${DOCKER_IMAGE}'
                        """
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'prod-server', keyFileVariable: 'SSH_KEY')]) {
                        // Check if container is running
                        sh """
                            ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${PROD_SERVER} '
                                if [ \$(docker ps -q -f name=new-container) ]; then
                                    echo "Container is running successfully"
                                else
                                    echo "Container failed to start" && exit 1
                                fi'
                        """
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo 'Deployment successful!'
            
            // Optional: Clean up local Docker image
            script {
                sh """
                    docker rmi ${DOCKER_IMAGE} || true
                """
            }
        }
        failure {
            echo 'Deployment failed!'
            
            // Optional: Rollback in case of failure
            script {
                withCredentials([sshUserPrivateKey(credentialsId: 'prod-server', keyFileVariable: 'SSH_KEY')]) {
                    sh """
                        ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${PROD_SERVER} '
                            # Stop and remove failed container
                            docker stop new-container || true
                            docker rm new-container || true
                            
                            # Remove failed image
                            docker rmi ${DOCKER_IMAGE} || true'
                    """
                }
            }
        }
        always {
            // Clean workspace after build
            cleanWs()
        }
    }
}
