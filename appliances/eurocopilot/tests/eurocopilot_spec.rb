require_relative '../../../lib/community/app_handler'

# Basic tests for EuroCopilot sovereign AI coding assistant appliance
describe 'Appliance Certification' do
    include_context('vm_handler')

    # Wait for the eurocopilot systemd service to become active.
    # Model load (~14 GiB Devstral on CPU) can take 2+ minutes after boot.
    it 'eurocopilot service is active' do
        cmd = 'systemctl is-active eurocopilot'
        start_time = Time.now
        timeout = 600

        loop do
            result = @info[:vm].ssh(cmd)
            break if result.stdout.strip == 'active'

            if Time.now - start_time > timeout
                raise "eurocopilot service did not become active within #{timeout} seconds"
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

    # The models endpoint lists the bundled Devstral model.
    it 'lists the devstral-small-2 model' do
        cmd = %q(
            password=$(cat /var/lib/eurocopilot/password)
            curl -sk -H "Authorization: Bearer ${password}" https://localhost:8443/v1/models
        )
        result = @info[:vm].ssh(cmd)
        expect(result.exitstatus).to eq(0)
        expect(result.stdout).to include('devstral-small-2')
    end

    # Chat completion returns a non-empty response.
    it 'completes a chat request' do
        cmd = %q(
            password=$(cat /var/lib/eurocopilot/password)
            curl -sk -H "Authorization: Bearer ${password}" \
                 -H "Content-Type: application/json" \
                 -d '{"model":"devstral-small-2","messages":[{"role":"user","content":"Say hello"}],"max_tokens":5}' \
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
        expect(result.stdout).to include('devstral-small-2')
    end
end
