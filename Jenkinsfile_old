pipeline {
  agent { label 'docker' }

  options {
    timestamps()
    timeout(time: 20, unit: 'MINUTES')
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '5'))
  }

  environment {
    IMAGE   = 'localhost:5001/shopease-api'
    VERSION = "1.0.${env.BUILD_NUMBER}"
  }

  stages {
    stage('Test') {
      steps {
        sh '''
          python3 -m venv .venv
          . .venv/bin/activate
          pip install --quiet -r requirements-dev.txt
          pytest -v --junitxml=test-report.xml
        '''
      }
      post {
        always {
          junit 'test-report.xml'
          archiveArtifacts artifacts: 'test-report.xml'
        }
      }
    }

    stage('Security scan') {
      steps {
        catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {
          sh '''
            . .venv/bin/activate
            pip install --quiet "pip-audit>=2.7,<3"
            pip-audit -r requirements.txt \
            --format json \
            --output pip-audit-report.json
          '''
        }
      }
    }

    stage('Build image') {
      steps {
        sh 'docker build --build-arg APP_VERSION="$VERSION" -t "$IMAGE:$VERSION" .'
      }
    }

    stage('Push image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'registry-creds',
                                          usernameVariable: 'REG_USER',
                                          passwordVariable: 'REG_PASS')]) {
          sh '''
            echo "$REG_PASS" | docker login localhost:5001 -u "$REG_USER" --password-stdin
            docker push "$IMAGE:$VERSION"
            docker logout localhost:5001
          '''
        }
      }
    }
  }

  post {
    success { echo "Built and pushed ${IMAGE}:${VERSION}" }
    failure { echo 'The build failed. Open the stage that turned red.' }
  }
}
