#!/usr/bin/env groovy

// Import required Jenkins pipeline libraries
import groovy.json.JsonOutput

def call(body) {
    // Initialize pipeline parameters
    def pipelineParams= [:]
    body.resolveStrategy = Closure.DELEGATE_FIRST
    body.delegate = pipelineParams
    body()

    pipeline {
        // Define which agent/node to run on
        agent {
            node {
                label pipelineParams.get('agentLabel', 'any')
            }
        }

        // Pipeline options
        options {
            // Prevent concurrent builds of the same branch
            disableConcurrentBuilds()
            // Enable colored output in console
            ansiColor('xterm')
        }

        // Environment variables available throughout the pipeline
        environment {
            // Load Snowflake credentials from Jenkins
            SNOWFLAKE_USER = credentials('snowflake-user')
            SNOWFLAKE_PASS = credentials('snowflake-password')
        }

        // Pipeline stages
        stages {
            // Setup environment variables and configuration
            stage('Setup Environment') {
                steps {
                    script {
                        // Read environment configuration
                        def envJson = readJSON(file: './configs/dev.json')
                        
                        // Set deployment parameters
                        env.DEPLOY_ENV = pipelineParams.get('envOverride', 'dev')
                        env.SESSION_NAME = "${env.SESSION_PREFIX}_${currentBuild.id}"
                        
                        // Get user input for deployment options
                        def deployParams = input(
                            message: 'Choose database type and flyway details:',
                            ok: 'Continue',
                            parameters: [
                                choice(
                                    name: 'FLYWAY_TASK',
                                    choices: ['info', 'migrate'],
                                    description: 'Info: Show pending changes, Migrate: Apply changes'
                                ),
                                choice(
                                    name: 'DATABASE_TYPE',
                                    choices: ['DEV_DB'],
                                    description: 'Target database'
                                ),
                                choice(
                                    name: 'WAREHOUSE',
                                    choices: ['COMPUTE_WH'],
                                    description: 'Snowflake warehouse to use'
                                )
                            ]
                        )

                        // Set deployment variables
                        env.FLYWAY_TASK = deployParams.FLYWAY_TASK
                        env.DEPLOY_DATABASE = deployParams.DATABASE_TYPE
                        env.DEPLOY_WAREHOUSE = deployParams.WAREHOUSE
                        env.DB_URL = "${envJson.jdbc_url}${envJson.account_name}/?db=${DEPLOY_DATABASE}&warehouse=${DEPLOY_WAREHOUSE}&role=${envJson.rolename}"
                        env.BASELINE = envJson.baseline_flag
                    }
                }
            }

            // Execute Flyway migration
            stage('Run Migration') {
                steps {
                    script {
                        // Make migration script executable
                        sh 'chmod +x ./sources/migrate_scripts.sh'
                        
                        // Execute migration script
                        sh """
                            ./sources/migrate_scripts.sh \
                            "\${DB_URL}" \
                            "\${SNOWFLAKE_USER}" \
                            "\${SNOWFLAKE_PASS}" \
                            "\${DEPLOY_DATABASE}" \
                            "\${DEPLOY_WAREHOUSE}" \
                            "\${FLYWAY_TASK}" \
                            "\${BASELINE}"
                        """
                    }
                }
            }
        }
    }
}