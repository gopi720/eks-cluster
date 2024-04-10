pipeline{
    agent any
    tools{
        maven "maven"
        terraform "Terraform"
    }
    environment{
       AWS_ACCESS_KEY_ID = credentials("accesskey")
       AWS_SECRET_ACCESS_KEY = credentials("secretkey")
       AWS_DEFAULT_REGION = "ap-south-1" 
       my_password = "Haritha"
    }
    parameters {
        choice(
            name: 'SELECT', // Name of the parameter
            choices: ['create', 'destroy'], // List of available choices
            description: 'Select the option to deploy to' // Description for the user
        )
    }
    stages{
        stage("git clone"){
            when {
                expression {
                    params.SELECT == 'create' 
                }
            }
            steps{
                git branch: 'main', url: 'https://github.com/gopi720/eks-cluster.git'
            }
        }
        stage("mvn build"){
            when {
                expression {
                    params.SELECT == 'create' 
                }
            }
            steps{
                sh 'mvn clean verify'
            }
        }
        stage("terraform"){
            when {
                expression {
                    params.SELECT == 'create' 
                }
            }
            steps{
                sh 'terraform init'
                script{
                    withCredentials([string(credentialsId: 'accesskey', variable: 'accesskey'), string(credentialsId: 'secretkey', variable: 'secretkey')]) {
                     sh '''
                      terraform plan -var accesskey=${accesskey} -var secretkey=${secretkey} 
                      terraform apply -var accesskey=${accesskey} -var secretkey=${secretkey} -auto-approve '''
                    }
                }
            }  
        }
        stage("terraform destroy"){
            when {
                expression {
                    params.SELECT == 'destroy' 
                }
            }
            steps{
               script{
                    withCredentials([string(credentialsId: 'accesskey', variable: 'accesskey'), string(credentialsId: 'secretkey', variable: 'secretkey')]) {
                     sh ' terraform destroy -var accesskey=${accesskey} -var secretkey=${secretkey} -auto-approve '
                    }
                } 
            }
        }
        stage("updating-kubectl"){
            when {
                expression {
                    params.SELECT == 'create' 
                }
            } 
            steps{
                sh 'aws eks update-kubeconfig --name k8scluster --region ap-south-1'
            }  
        }
        stage("kubectl node checking"){
            when {
                expression {
                    params.SELECT == 'create' 
                }
            } 
            steps{
                sh 'kubectl get nodes -o wide'
            } 
        }
        stage("docker image build and push"){
            when {
                expression {
                    params.SELECT == 'create' 
                }  
            }
            steps{
                script{
                    withCredentials([string(credentialsId: 'docker', variable: 'docker')]) {
                     sh 'docker login -u gopidharani -p ${docker}'      
                    }
                  sh ''' docker build -t gopidharani/airtelcare:2.0 .
                   docker image push gopidharani/airtelcare:2.0'''
                }
            }    
        }
        stage("clearing environment"){
            when {
                expression {
                    params.SELECT == 'create' 
                }  
            } 
            steps{
                sh '''kubectl delete -f airtelcarepod.yml
                kubectl delete -f airtelcare2-service.yml'''
            }   
        }
        stage("deployment"){
           when {
                expression {
                    params.SELECT == 'create' 
                }  
            } 
            steps{
                sh '''kubectl apply -f airtelcarepod.yml
                kubectl apply -f airtelcare2-service.yml'''
            }
        }
        stage("getting services"){
            when {
                expression {
                    params.SELECT == 'create' 
                }  
            } 
            steps{
                sh '''kubectl get pods -o wide 
                kubectl get services'''
            }   
        }
        stage("checking container logs"){
            when {
                expression {
                    params.SELECT == 'create' 
                }  
            } 
            steps{
                sh 'kubectl describe pod airtelcare'
            }   
        }
    }
}
