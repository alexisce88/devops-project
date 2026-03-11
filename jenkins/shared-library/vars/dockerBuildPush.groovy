/**
 * dockerBuildPush.groovy — Shared library step
 * Builds a Docker image and pushes it to GHCR.
 *
 * Usage:
 *   dockerBuildPush(
 *     context: 'app/backend',
 *     imageName: 'ghcr.io/alexisce88/devops-backend',
 *     tag: env.GIT_COMMIT.take(7)
 *   )
 */
def call(Map config = [:]) {
    def context   = config.get('context', '.')
    def imageName = config.get('imageName')
    def tag       = config.get('tag', 'latest')
    def buildArgs = config.get('buildArgs', [:])

    if (!imageName) {
        error('dockerBuildPush: imageName is required')
    }

    def fullTag  = "${imageName}:${tag}"
    def latestTag = "${imageName}:latest"

    // Build --build-arg string
    def buildArgStr = buildArgs.collect { k, v -> "--build-arg ${k}=${v}" }.join(' ')

    withCredentials([usernamePassword(
        credentialsId: 'ghcr-creds',
        usernameVariable: 'DOCKER_USER',
        passwordVariable: 'DOCKER_PASS'
    )]) {
        sh "echo \${DOCKER_PASS} | docker login ghcr.io -u \${DOCKER_USER} --password-stdin"

        sh "docker build ${buildArgStr} -t ${fullTag} -t ${latestTag} ${context}"

        sh "docker push ${fullTag}"
        sh "docker push ${latestTag}"

        // Clean up local images to save disk space on t3.small
        sh "docker rmi ${fullTag} ${latestTag} || true"
    }

    echo "Image pushed: ${fullTag}"
    return fullTag
}
