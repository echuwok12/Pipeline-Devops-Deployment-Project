pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'test:latest'
        PROD_SERVER = 'azureuser@20.2.217.99'
        SONAR_PROJECT_KEY = 'DevOpPipeline'
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
        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner' 
                    withSonarQubeEnv('SonarServer') { 
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                            -Dsonar.projectName=${SONAR_PROJECT_KEY} \
                            -Dsonar.sources=. \
                            -Dsonar.host.url=${SONAR_HOST_URL} \
                            -Dsonar.sourceEncoding=UTF-8 \
                            -Dsonar.html.file.suffixes=html,htm \
                            -Dsonar.css.file.suffixes=css \
                            -Dsonar.exclusions=Dockerfile,Jenkinsfile,README.md,*.properties,*.json,*.yml,*.yaml,*.xml,node_modules/**,vendor/** \
                            -Dsonar.coverage.exclusions=**/*test*/**/*,**/*.min.js,**/*.min.css
                        """
                    }

                    // Quality Gate
                    timeout(time: 10, unit: 'MINUTES') {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline aborted due to quality gate failure: ${qg.status}"
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
                    withCredentials([sshUserPrivateKey(credentialsId: 'prod-server', keyFileVariable: 'SSH_KEY')]) {
                        // First verify if we can connect to the server
                        sh """#!/bin/bash
                            ssh -i "\${SSH_KEY}" -o StrictHostKeyChecking=no ${PROD_SERVER} 'echo "SSH connection successful"'
                        """
                        
                        // Save and transfer Docker image
                        sh """#!/bin/bash
                            docker save ${DOCKER_IMAGE} | ssh -i "\${SSH_KEY}" -o StrictHostKeyChecking=no ${PROD_SERVER} 'docker load'
                        """
                        
                        // Deploy the container
                        sh """#!/bin/bash
                            ssh -i "\${SSH_KEY}" -o StrictHostKeyChecking=no ${PROD_SERVER} '
                                # Stop and remove existing container if it exists
                                docker stop new-container || true
                                docker rm new-container || true
                                
                                # Run new container
                                docker run -d \\
                                    --name new-container \\
                                    --restart unless-stopped \\
                                    -p 80:80 \\
                                    ${DOCKER_IMAGE}
                            '
                        """
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'prod-server', keyFileVariable: 'SSH_KEY')]) {
                        sh """#!/bin/bash
                            ssh -i "\${SSH_KEY}" -o StrictHostKeyChecking=no ${PROD_SERVER} '
                                if [ \$(docker ps -q -f name=new-container) ]; then
                                    echo "Container is running successfully"
                                    docker ps -f name=new-container
                                else
                                    echo "Container failed to start"
                                    exit 1
                                fi
                            '
                        """
                    }
                }
            }
        }
        stage('Verify Website') {
    steps {
        script {
            withCredentials([sshUserPrivateKey(credentialsId: 'prod-server', keyFileVariable: 'SSH_KEY')]) {
                sh """#!/bin/bash
                    ssh -i "\${SSH_KEY}" -o StrictHostKeyChecking=no ${PROD_SERVER} '
                        # Check if nginx is running
                        docker exec new-container nginx -t
                        
                        # Check if the site is accessible locally
                        curl -f http://localhost:80 || echo "Website not accessible"
                        
                        # Check nginx logs
                        docker logs new-container
                        
                        # Check mounted content
                        docker exec new-container ls -la /usr/share/nginx/html/
                    '
                """
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
            echo 'Deployment failed!'
            
            script {
                withCredentials([sshUserPrivateKey(credentialsId: 'prod-server', keyFileVariable: 'SSH_KEY')]) {
                    sh """#!/bin/bash
                        ssh -i "\${SSH_KEY}" -o StrictHostKeyChecking=no ${PROD_SERVER} '
                            docker logs new-container || true
                            docker ps -a | grep new-container || true
                        '
                    """
                }
            }
        }
        always {
            cleanWs()
        }
    }
}
