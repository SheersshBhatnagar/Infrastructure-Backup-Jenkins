
pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    environment {
        PROJECT_DIR = '/opt/infrastructure-backup'
        S3_BUCKET = 'sheerssh-infrastructure-backup-2026'

        AWS_ACCESS_KEY_ID = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
        AWS_DEFAULT_REGION = 'ap-south-1'
    }

    stages {

        stage('Validate Environment') {
            steps {
                echo 'Checking environment...'

                sh '''
                    set -eu

                    command -v aws
                    command -v tar
                    command -v sha256sum

                    test -x "$PROJECT_DIR/scripts/backup.sh"
                    test -x "$PROJECT_DIR/scripts/cleanup.sh"

                    aws sts get-caller-identity

                    echo "Environment validation successful!"
                '''
            }
        }

        stage('Create Backup') {
            steps {
                echo 'Creating application backup...'

                sh '''
                    "$PROJECT_DIR/scripts/backup.sh"
                '''
            }
        }

        stage('Verify Backup') {
            steps {
                echo 'Verifying backup integrity...'

                sh '''
                    set -eu

                    cd "$PROJECT_DIR/backups"

                    LATEST_BACKUP=$(
                        find . -maxdepth 1 \
                        -type f \
                        -name 'application_backup_*.tar.gz' \
                        -printf '%T@ %f\\n' |
                        sort -nr |
                        head -1 |
                        cut -d' ' -f2-
                    )

                    if [ -z "$LATEST_BACKUP" ]; then
                        echo "No backup found!"
                        exit 1
                    fi

                    echo "Checking $LATEST_BACKUP"

                    sha256sum -c "$LATEST_BACKUP.sha256"

                    aws s3api head-object \
                        --bucket "$S3_BUCKET" \
                        --key "backups/$LATEST_BACKUP"

                    aws s3api head-object \
                        --bucket "$S3_BUCKET" \
                        --key "backups/$LATEST_BACKUP.sha256"

                    echo "Backup verification successful!"
                '''
            }
        }

        stage('Local Backup Cleanup') {
            steps {
                echo 'Cleaning old local backups...'

                sh '''
                    "$PROJECT_DIR/scripts/cleanup.sh"
                '''
            }
        }
    }

    post {
        success {
            echo 'BACKUP PIPELINE COMPLETED SUCCESSFULLY!'
        }

        failure {
            echo 'BACKUP PIPELINE FAILED!'
            echo 'Check Console Output for errors.'
        }

        always {
            echo 'Infrastructure Backup Pipeline Finished.'
        }
    }
}

