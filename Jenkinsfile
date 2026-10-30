pipeline {
  agent none

  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '15', artifactNumToKeepStr: '5'))
  }

  triggers {
    pollSCM('H/2 * * * *')
  }

  environment {
    IMAGE   = 'localhost:5001/shopease-api'
    VERSION = "1.0.${env.BUILD_NUMBER}"
  }

  stages {

    stage('CI: test, scan, build, publish') {
      agent { label 'docker' }
      options { timeout(time: 20, unit: 'MINUTES') }
      stages {

        stage('Decide the release path') {
          steps {
            script {
              env.ON_MAIN = (env.GIT_BRANCH in ['origin/main', 'main']) ? 'true' : 'false'
            }
            echo "Branch: ${env.GIT_BRANCH}. Release path allowed: ${env.ON_MAIN}"
          }
        }

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
            }
          }
        }

        stage('Security scan') {
          steps {
            catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {
              sh '''
                . .venv/bin/activate
                pip install --quiet "pip-audit>=2.7,<3"
                pip-audit -r requirements.txt
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
                trap 'docker logout localhost:5001 >/dev/null 2>&1' EXIT
                echo "$REG_PASS" | docker login localhost:5001 -u "$REG_USER" --password-stdin
                docker push "$IMAGE:$VERSION"
              '''
            }
          }
        }

        stage('Package and archive') {
          steps {
            sh '''
              mkdir -p dist
              zip -r "dist/shopease-api-$VERSION.zip" app.py requirements.txt Dockerfile scripts
              DIGEST=$(docker inspect --format '{{index .RepoDigests 0}}' "$IMAGE:$VERSION")
              printf 'version=%s\nimage=%s\ndigest=%s\ncommit=%s\nbuild_url=%s\n' "$VERSION" "$IMAGE:$VERSION" "$DIGEST" "$GIT_COMMIT" "$BUILD_URL" > dist/build-info.txt
              (cd dist && sha256sum *.zip > checksums.txt)
            '''
            archiveArtifacts artifacts: 'dist/*', fingerprint: true, onlyIfSuccessful: true
            stash name: 'release-package', includes: 'dist/**'
          }
        }

        stage('Verify package on another agent') {
          agent { label 'agent-2' }
          steps {
            unstash 'release-package'
            sh 'cd dist && sha256sum -c checksums.txt'
          }
        }
      }
      post {
        cleanup { cleanWs() }
      }
    }

    stage('Deploy to staging') {
      when {
        beforeAgent true
        environment name: 'ON_MAIN', value: 'true'
      }
      agent { label 'docker' }
      options { timeout(time: 10, unit: 'MINUTES') }
      steps {
        withCredentials([usernamePassword(credentialsId: 'registry-creds',
                                          usernameVariable: 'REG_USER',
                                          passwordVariable: 'REG_PASS')]) {
          sh '''
            trap 'docker logout localhost:5001 >/dev/null 2>&1' EXIT
            echo "$REG_PASS" | docker login localhost:5001 -u "$REG_USER" --password-stdin
            bash scripts/deploy.sh staging 8081 "$IMAGE:$VERSION"
          '''
        }
        sh 'bash scripts/smoke_test.sh shopease-staging'
      }
    }

    stage('Approve production release') {
      when {
        beforeInput true
        environment name: 'ON_MAIN', value: 'true'
      }
      options { timeout(time: 30, unit: 'MINUTES') }
      input {
        message "Release ${VERSION} to PRODUCTION?"
        ok 'Approve and deploy'
        submitter 'admin,release-manager'
        submitterParameter 'APPROVER'
      }
      steps {
        echo "Release ${VERSION} approved by ${APPROVER}"
      }
    }

    stage('Deploy to production') {
      when {
        beforeAgent true
        environment name: 'ON_MAIN', value: 'true'
      }
      agent { label 'docker' }
      options { timeout(time: 10, unit: 'MINUTES') }
      steps {
        withCredentials([usernamePassword(credentialsId: 'registry-creds',
                                          usernameVariable: 'REG_USER',
                                          passwordVariable: 'REG_PASS')]) {
          sh '''
            trap 'docker logout localhost:5001 >/dev/null 2>&1' EXIT
            echo "$REG_PASS" | docker login localhost:5001 -u "$REG_USER" --password-stdin
            bash scripts/deploy.sh production 8082 "$IMAGE:$VERSION"
          '''
        }
        sh 'bash scripts/smoke_test.sh shopease-production'
      }
    }
  }

  post {
    success { echo "Pipeline finished. Version ${VERSION} is released." }
    aborted { echo 'Pipeline stopped: approval was refused or timed out.' }
    failure { echo 'Pipeline failed. Open the red stage.' }
  }
}
