/**
 * runHealthCheck.groovy — Shared library step
 * Polls an HTTP endpoint until it returns 200 or timeout expires.
 *
 * Usage:
 *   runHealthCheck(url: "http://${STAGING_IP}:3001/health", retries: 12, delay: 10)
 */
def call(Map config = [:]) {
    def url     = config.get('url')
    def retries = config.get('retries', 12)
    def delay   = config.get('delay', 10)
    def label   = config.get('label', url)

    if (!url) {
        error('runHealthCheck: url is required')
    }

    echo "Health check: ${label}"

    def passed = false
    for (int i = 1; i <= retries; i++) {
        def code = sh(
            script: "curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 '${url}'",
            returnStdout: true
        ).trim()

        if (code == '200') {
            echo "Health check passed (attempt ${i}/${retries}): ${label}"
            passed = true
            break
        }

        echo "Attempt ${i}/${retries}: HTTP ${code} — retrying in ${delay}s..."
        sleep(delay)
    }

    if (!passed) {
        error("Health check failed after ${retries} attempts: ${label}")
    }
}
