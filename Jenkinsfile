pipeline {
    agent any
    stages {
        stage('Get Code') {
            steps {
                sh'''
                    whoami
                    hostname
                    mkdir -p ~/.ssh/
                    ssh-keyscan -t rsa,dsa github.com >> ~/.ssh/known_hosts
                    if [ "$BRANCH_NAME" == "develop" ]; then
                        export ENV="staging"
                    elif [ "$BRANCH_NAME" == "master" ]; then
                        export ENV="production"
                    fi
                '''
                git branch: '$BRANCH_NAME', url:'git@github.com:varodev/todo-list-aws.git', credentialsId: 'github_rsa'
                dir('configs') {
                    git branch: '$ENV', url:'git@github.com:varodev/todo-list-aws-config.git', credentialsId: 'github_rsa'
                }
                stash name: "repo", includes: "*"
            }
        }
        stage('Static Test') {
            when {
                branch "develop"
            }
            agent {
              label 'static'
            }
            steps {
                unstash "repo"
                sh '''
                    whoami
                    hostname
                    ./deps.sh
                    python3 -m flake8 --format=pylint --output=result-flake8.txt --exit-zero src/*
                    python3 -m bandit -r . -o result-bandit.xml --exit-zero -f xml
                '''
                stash name: "static", includes: "result-flake8.txt"
                stash name: "security", includes: "result-bandit.xml"
                recordIssues tools: [flake8(pattern: 'result-flake8.txt')], enabledForFailure: true
                recordIssues tools: [junitParser(pattern: 'result-bandit.xml', id: 'bandit', name: 'Bandit Security')], enabledForFailure: true
            }
        }
        stage('Deploy') {
            when {
                branch "develop"
                branch "master"
            }
            steps {
                sh '''
                    whoami
                    hostname
                    if [ "$BRANCH_NAME" == "develop" ]; then
                        export ENV="staging"
                    elif [ "$BRANCH_NAME" == "master" ]; then
                        export ENV="production"
                    fi
                    sam build --config-env $ENV --config-file configs/samconfig.toml
                    sam validate --region us-east-1 --config-file configs/samconfig.toml
                    sam deploy --config-env $ENV --config-file configs/samconfig.toml --debug --no-fail-on-empty-changeset
                    sam list stack-outputs --stack-name todo-list-aws-$ENV --region us-east-1 --output json > out.json
                '''
            stash name: "samout", includes: "out.json"
            }
        }
        stage('Rest Test') {
            agent {
              label 'rest'
            }
            steps {
                unstash 'repo'
                unstash 'samout'
                sh '''
                    whoami
                    hostname
                    export BASE_URL=$(jq ".[0].OutputValue" out.json -r)
                    echo $BASE_URL
                    python3 -m pip install pytest
                    python3 -m pytest --junitxml=result-rest.xml test/integration/*.py
                '''
                stash name: "rest", includes: "result-rest.xml"
                junit 'result-rest.xml'
            }
        }
        stage('Promote') {
            environment {
                GIT_AUTH = credentials('github_rsa')
            }
            when {
                branch "develop"
            }
            steps {
                sh '''
                    whoami
                    hostname
                    git config --global user.name "Aparicio"
                    git config --global user.password "alvmorapa87@gmail.com"
                    git checkout master
                    git merge develop
                '''
                withCredentials([sshUserPrivateKey(credentialsId: 'github_rsa', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    withEnv(["GIT_SSH_COMMAND=ssh -o StrictHostKeyChecking=no -o User=${SSH_USER} -i ${SSH_KEY}"]) {
                        sh 'git push origin master:master'
                    }
                }
            }
        }
    }
}