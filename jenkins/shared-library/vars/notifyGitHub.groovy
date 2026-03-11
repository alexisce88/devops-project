/**
 * notifyGitHub.groovy — Shared library step
 * Posts a commit status to GitHub and (optionally) a PR comment.
 *
 * Usage:
 *   notifyGitHub(state: 'pending', description: 'CI running...')
 *   notifyGitHub(state: 'success', description: 'All checks passed')
 *   notifyGitHub(state: 'failure', description: 'Tests failed', prComment: true)
 */
def call(Map config = [:]) {
    def state       = config.get('state', 'pending')        // pending | success | failure | error
    def description = config.get('description', '')
    def context     = config.get('context', 'ci/jenkins')
    def prComment   = config.get('prComment', false)

    def repoUrl = env.GIT_URL ?: sh(script: 'git remote get-url origin', returnStdout: true).trim()
    def repoPath = repoUrl.replaceAll(/.*github\.com[\/:]/, '').replaceAll(/\.git$/, '')
    def sha      = env.GIT_COMMIT ?: sh(script: 'git rev-parse HEAD', returnStdout: true).trim()

    withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
        def payload = groovy.json.JsonOutput.toJson([
            state      : state,
            description: description,
            context    : context,
            target_url : env.BUILD_URL ?: ''
        ])

        sh """
            curl -s -X POST \\
              -H 'Authorization: token ${GITHUB_TOKEN}' \\
              -H 'Accept: application/vnd.github.v3+json' \\
              -H 'Content-Type: application/json' \\
              -d '${payload}' \\
              "https://api.github.com/repos/${repoPath}/statuses/${sha}"
        """

        // Post a PR comment only on PRs (CHANGE_ID is set by Multibranch Pipeline)
        if (prComment && env.CHANGE_ID) {
            def emoji = state == 'success' ? '✅' : (state == 'failure' ? '❌' : '⏳')
            def commentBody = groovy.json.JsonOutput.toJson([
                body: "${emoji} **Jenkins CI** — ${description}\n\nBuild: [#${env.BUILD_NUMBER}](${env.BUILD_URL})"
            ])

            sh """
                curl -s -X POST \\
                  -H 'Authorization: token ${GITHUB_TOKEN}' \\
                  -H 'Accept: application/vnd.github.v3+json' \\
                  -H 'Content-Type: application/json' \\
                  -d '${commentBody}' \\
                  "https://api.github.com/repos/${repoPath}/issues/${env.CHANGE_ID}/comments"
            """
        }
    }
}
