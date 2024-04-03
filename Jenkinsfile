pipeline{
    agent any
    tools{
        maven "maven"
        terraform "Terraform"
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
    }

}
