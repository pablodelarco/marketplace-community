require_relative '../../../lib/community/app_handler'

# Basic tests for EuroCopilot sovereign AI coding assistant appliance
describe 'Appliance Certification' do
    include_context('vm_handler')

    # Wait for the appliance to be fully ready, not merely for systemd to report
    # "active". llama-server binds port 8443 ~5 seconds into boot but then mmaps
    # the GGUF into RAM and warms up the KV cache, during which time the HTTP
    # API answers with 503 {"message":"Loading model"}. The one-apps
    # service_bootstrap step waits for /health to return 200 and only then
    # writes /etc/one-appliance/config -- so gating on both conditions mirrors
    # the appliance's own definition of "ready" and makes the rest of the spec
    # race-free.
    #
    # Built-in Mistral 7B Instruct (~4 GiB) loads in ~30-90s on a 2 vCPU /
    # 8 GiB test VM. Users who select a larger opt-in model (12B / 24B) pay
    # an additional ~5-10 min for the Hugging Face download on first boot.
    # The 600 s timeout covers either path with comfortable margin.
    it 'appliance reaches ready state' do
        start_time = Time.now
        timeout = 600

        loop do
            health = @info[:vm].ssh('curl -sk -o /dev/null -w "%{http_code}" https://localhost:8443/health')
            report = @info[:vm].ssh('test -f /etc/one-appliance/config')
            break if health.stdout.strip == '200' && report.success?

            if Time.now - start_time > timeout
                raise "appliance did not reach ready state within #{timeout}s " \
                      "(last health=#{health.stdout.strip}, report=#{report.success? ? 'present' : 'missing'})"
            end

            sleep 10
        end
    end

    # Verify the HTTPS API is listening on port 8443.
    it 'listens on https port 8443' do
        cmd = 'ss -tln | grep -q ":8443"'
        result = @info[:vm].ssh(cmd)
        expect(result.exitstatus).to eq(0)
    end

    # Health endpoint is unauthenticated and returns 200.
    it 'returns 200 on /health without auth' do
        cmd = 'curl -sk -o /dev/null -w "%{http_code}" https://localhost:8443/health'
        result = @info[:vm].ssh(cmd)
        expect(result.stdout.strip).to eq('200')
    end

    # Root endpoint requires authentication (401 without bearer).
    it 'returns 401 on / without auth' do
        cmd = 'curl -sk -o /dev/null -w "%{http_code}" https://localhost:8443/'
        result = @info[:vm].ssh(cmd)
        expect(result.stdout.strip).to eq('401')
    end

    # The models endpoint lists the bundled Mistral 7B Instruct model.
    it 'lists the mistral-7b model' do
        cmd = %q(
            password=$(cat /var/lib/eurocopilot/password)
            curl -sk -H "Authorization: Bearer ${password}" https://localhost:8443/v1/models
        )
        result = @info[:vm].ssh(cmd)
        expect(result.exitstatus).to eq(0)
        expect(result.stdout).to include('mistral-7b')
    end

    # Chat completion returns a non-empty response.
    it 'completes a chat request' do
        cmd = %q(
            password=$(cat /var/lib/eurocopilot/password)
            curl -sk -H "Authorization: Bearer ${password}" \
                 -H "Content-Type: application/json" \
                 -d '{"model":"mistral-7b","messages":[{"role":"user","content":"Say hello"}],"max_tokens":5}' \
                 https://localhost:8443/v1/chat/completions
        )
        result = @info[:vm].ssh(cmd)
        expect(result.exitstatus).to eq(0)
        expect(result.stdout).to include('"choices"')
    end

    # The report file written by service_configure exposes connection details.
    it 'has the report file with connection info' do
        cmd = 'cat /etc/one-appliance/config'
        result = @info[:vm].ssh(cmd)
        expect(result.exitstatus).to eq(0)
        expect(result.stdout).to include('endpoint')
        expect(result.stdout).to include('api_key')
        expect(result.stdout).to include('mistral-7b')
    end
end
