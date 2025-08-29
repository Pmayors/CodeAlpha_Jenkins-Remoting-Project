pipeline {
    agent none

    environment {
        DOCKER_IMAGE = "pmayors/jenkinsjob:latest"
    }

    stages {
        stage('Build with Maven') {
            agent { label 'agentmaven' }
            steps {
                // Pull Spring PetClinic project from GitHub (public repo)
                git branch: 'main', url: 'https://github.com/spring-projects/spring-petclinic.git'

                // Build the project (skip tests)
                sh 'mvn clean package -DskipTests'

                // Save jar artifact for later stages
                stash includes: 'target/*.jar', name: 'app-jar'
            }
        }

        // Skipping Test stage as per your setup
        // stage('Test with Maven') {
        //     agent { label 'agentmaven' }
        //     steps {
        //         sh 'mvn test'
        //     }
        //     post {
        //         always {
        //             junit 'target/surefire-reports/*.xml'
        //         }
        //     }
        // }

        stage('Run on Windows Agent') {
            agent { label 'windows' }
            steps {
                echo "Running a task on the Windows agent..."
                bat 'echo Hello from Windows Agent > windows_task.txt'
                bat 'type windows_task.txt'
            }
            post {
                always {
                    // Archive the output from Windows agent for verification
                    archiveArtifacts artifacts: 'windows_task.txt', fingerprint: true
                    echo "Windows agent task output archived."
                }
            }
        }

        stage('Docker Build & Push') {
            agent { label 'agentdocker' }
            steps {
                // Retrieve the JAR file from Maven build
                unstash 'app-jar'

                // Create Dockerfile dynamically (Java 17 & correct jar name)
                sh '''
                cp target/spring-petclinic-*.jar app.jar
                echo "FROM openjdk:17-jdk-slim" > Dockerfile
                echo "COPY app.jar /app.jar" >> Dockerfile
                echo 'ENTRYPOINT ["java","-jar","/app.jar"]' >> Dockerfile
                '''

                // Build and push Docker image
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh '''
                    docker build -t $DOCKER_IMAGE .
                    echo $PASS | docker login -u $USER --password-stdin
                    docker push $DOCKER_IMAGE
                    '''
                }
            }
        }

        stage('Deploy on Docker Agent') {
            agent { label 'agentdocker' }
            steps {
                // Stop & remove old container if it exists, then run new one
                sh '''
                docker stop jenkinsjob || true
                docker rm jenkinsjob || true
                docker run -d --name jenkinsjob -p 8080:8080 $DOCKER_IMAGE

                echo "=== Running Containers ==="
                docker ps

                echo "=== Last 50 container logs ==="
                docker logs --tail=50 jenkinsjob || true
                '''
            }
        }
    }
}
