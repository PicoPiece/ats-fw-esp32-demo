pipeline {
    agent none

    parameters {
        string(
            name: 'BRANCH_NAME',
            defaultValue: 'main',
            description: 'Git branch to build (e.g., main, develop, feature/xxx)'
        )
        booleanParam(
            name: 'TRIGGER_TEST',
            defaultValue: true,
            description: 'Trigger test pipeline after build completes'
        )
        string(
            name: 'TAG_PREFIX',
            defaultValue: 'fw',
            description: 'Prefix for firmware tag (e.g., fw, v, release)'
        )
    }

    environment {
        FW_ARTIFACT = "firmware.bin"
    }

    stages {

        stage('Checkout Source') {
            agent { label 'fw-build' }   // 🚨 Xeon build agent
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${params.BRANCH_NAME}"]],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [],
                    submoduleCfg: [],
                    userRemoteConfigs: scm.userRemoteConfigs
                ])
            }
        }

        stage('Build ESP32 Firmware (Xeon)') {
            agent { label 'fw-build' }   // 🚨 build ONLY here
            steps {
                sh '''
                    export ESPRESSIF_HOME=/home/jenkins/.espressif
                    . /opt/esp/idf/export.sh
                    idf.py set-target esp32
                    idf.py build
                    cp build/*.bin ${FW_ARTIFACT}
                '''
            }
        }

        stage('Archive Firmware Artifact (Xeon)') {
            agent { label 'fw-build' }
            steps {
                archiveArtifacts artifacts: "${FW_ARTIFACT}", fingerprint: true
            }
        }

        stage('Generate ATS Manifest (Xeon)') {
            agent { label 'fw-build' }
            steps {
                sh '''
                    SHA256=$(sha256sum ${FW_ARTIFACT} | awk '{print $1}')

                    cat <<EOF > ats-manifest.yaml
manifest_version: 1

build:
  ci_system: jenkins
  job_name: ${JOB_NAME}
  build_number: ${BUILD_NUMBER}
  git:
    repo: ${GIT_URL}
    commit: ${GIT_COMMIT}
    branch: ${GIT_BRANCH}
  artifact:
    name: ${FW_ARTIFACT}
    checksum: sha256:${SHA256}
    build_node: xeon-fw-build

device:
  target: esp32
  board: esp32-devkit

test_plan:
  - gpio_toggle_test
  - oled_display_test

timestamps:
  build_time: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
EOF
                '''
                archiveArtifacts artifacts: 'ats-manifest.yaml'
            }
        }

        stage('Tag Firmware') {
            agent { label 'fw-build' }
            steps {
                script {
                    def tagName = "${params.TAG_PREFIX}-${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
                    def tagMessage = "Firmware build #${env.BUILD_NUMBER} from ${env.GIT_BRANCH}"
                    
                    sh """
                        git config user.name "Jenkins"
                        git config user.email "jenkins@ats-ci"
                        git tag -a ${tagName} -m "${tagMessage}"
                        git push origin ${tagName} || echo "Tag push failed (may already exist)"
                    """
                    
                    echo "✅ Tagged firmware: ${tagName}"
                }
            }
        }

        stage('Trigger Test Pipeline') {
            when {
                expression { params.TRIGGER_TEST == true }
            }
            steps {
                script {
                    def testJobName = "${env.JOB_NAME}-test"
                    echo "🚀 Triggering test pipeline: ${testJobName}"
                    
                    def testBuild = build job: testJobName, 
                        parameters: [
                            string(name: 'BUILD_JOB_NAME', value: env.JOB_NAME),
                            string(name: 'BUILD_NUMBER', value: env.BUILD_NUMBER.toString()),
                            string(name: 'FW_ARTIFACT', value: env.FW_ARTIFACT)
                        ],
                        wait: false,
                        propagate: false
                    
                    echo "✅ Test pipeline triggered: ${testJobName} #${testBuild.number}"
                }
            }
        }
    }

    post {
        success {
            echo "✅ Firmware built and tagged successfully"
        }
        failure {
            echo "❌ Firmware build failed"
        }
        always {
            node('fw-build') {
                archiveArtifacts artifacts: 'ats-manifest.yaml', allowEmptyArchive: true
            }
        }
    }
}
