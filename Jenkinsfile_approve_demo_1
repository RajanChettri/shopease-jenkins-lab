pipeline {
    agent { label 'docker' }

    stages {

        stage('Checkout and Test') {
            steps {
                echo 'Testing ShopEase application...'

                sh '''
                    python3 -m venv .venv
                    . .venv/bin/activate
                    pip install --quiet -r requirements-dev.txt
                    pytest -v
                '''
            }
        }

        stage('Build Approval') {
            steps {
                input message: 'Do you approve this build for release?',
                      ok: 'Approve',
                      submitter: 'admin'
            }
        }

        stage('Release') {
            steps {
                echo 'Build approved! ShopEase is ready for release.'
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }

        aborted {
            echo 'Build approval was rejected or cancelled.'
        }

        failure {
            echo 'Pipeline failed. Check the console output.'
        }
    }
}
