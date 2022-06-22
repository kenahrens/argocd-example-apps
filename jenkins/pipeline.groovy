pipeline {
    agent any

    environment {
        APP_URL = 'app.speedscale.com'
        TENANT_ID = ''
        TENANT_NAME = ''
        TENANT_BUCKET = ''
        TENANT_API_KEY = ''
        TENANT_STREAM = ''
        PATH = "/home/jenkins/.speedscale:${env.PATH}"
    }

    stages {
        stage('Checkout') {
            steps {
                git credentialsId: 'jenkins-deleteme3', url: 'git@github.com:kenahrens/argocd-example-apps.git'
            }
        }
        stage('Setup') {
            steps {
                sh 'echo $PATH'
                sh 'echo "Installing jq"'
                sh 'curl https://stedolan.github.io/jq/download/linux64/jq --output ~/.speedscale/jq'
                sh 'chmod +x ~/.speedscale/jq'
                sh 'echo "Installing speedctl"'
                sh './tools/create-config.sh'
                sh 'sh -c "$(curl -sL https://downloads.speedscale.com/speedctl/install)"'
                sh 'echo "Installing argocd"'
                sh 'curl -sSL https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 --output ~/.speedscale/argocd'
                sh 'chmod +x ~/.speedscale/argocd'
                sh 'argocd login argocd-server.argocd.svc.cluster.local:443 --username admin --password ABCD123! --insecure'
            }
        }
        stage('Replay') {
            steps {
                withCredentials([file(credentialsId: 'ID_RSA', variable: 'ID_RSA'), file(credentialsId: 'ID_RSA_PUB', variable: 'ID_RSA_PUB')]) {
                    // sh 'mkdir ~/.ssh'
                    sh 'cat $ID_RSA > ~/.ssh/id_rsa'
                    sh 'chmod 600 ~/.ssh/id_rsa'
                    sh 'cat $ID_RSA_PUB > ~/.ssh/id_rsa.pub'
                    sh 'chmod 600 ~/.ssh/id_rsa.pub'
                    sh 'echo $PATH'
                    sh '''./tools/create-replay.sh \
                            --dest-dir podtato \
                            --workload-name podtato-head-entry \
                            --snapshot-id a1b72cbd-cf47-4e3c-b9b9-b78f693dbcf6
                        '''
                }
            }
        }
    }
}
