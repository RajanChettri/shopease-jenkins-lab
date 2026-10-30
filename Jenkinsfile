```groovy
pipeline {
    agent { label 'docker' }

    stages {

        stage('Test') {
            steps {
                echo 'Running ShopEase tests...'

                sh '''
                    python3 -m venv .venv
                    . .venv/bin/activate
                    pip install --quiet -r requirements-dev.txt
                    pytest -v
                '''
            }
        }

        stage('Release Manager Approval') {
            steps {
                input message: 'Release ShopEase to production?',
                      ok: 'Approve Release',
                      submitter: 'release-manager',
                      submitterParameter: 'APPROVER'
            }
        }

        stage('Production Release') {
            steps {
                echo "Production release approved by ${env.APPROVER}"
                echo 'ShopEase production release completed!'
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }

        aborted {
            echo 'Release rejected or approval cancelled.'
        }

        failure {
            echo 'Pipeline failed. Check the console output.'
        }
    }
}
```
