require_relative '../../../lib/community/app_handler'

describe 'Phoenix RTOS Appliance' do
    include_context('vm_handler')

    # Test Docker installation
    it 'docker is installed and running' do
        cmd = 'which docker'
        @info[:vm].ssh(cmd).expect_success

        cmd = 'systemctl is-active docker'
        @info[:vm].ssh(cmd).expect_success
    end

    # Test Phoenix RTOS container image is available
    it 'phoenix rtos container image is available' do
        cmd = 'docker images --format "{{.Repository}}:{{.Tag}}" | grep "pablodelarco/phoenix-rtos-one:latest"'
        @info[:vm].ssh(cmd).expect_success
    end

    # Test data directory exists
    it 'data directory exists' do
        cmd = 'test -d /data'
        @info[:vm].ssh(cmd).expect_success
    end

    # Test Phoenix RTOS container is running
    it 'phoenix rtos container is running' do
        cmd = 'docker ps --format "{{.Names}}" | grep "phoenix-rtos-one"'
        @info[:vm].ssh(cmd).expect_success
    end

    # Test container is responsive
    it 'phoenix rtos container is responsive' do
        cmd = 'docker exec phoenix-rtos-one echo "Container is running"'
        execution = @info[:vm].ssh(cmd)
        expect(execution.success?).to be(true)
        expect(execution.stdout.strip).to eq('Container is running')
    end

    # Test container has correct restart policy
    it 'container has restart policy configured' do
        cmd = 'docker inspect phoenix-rtos-one --format "{{.HostConfig.RestartPolicy.Name}}"'
        execution = @info[:vm].ssh(cmd)
        expect(execution.success?).to be(true)
        expect(execution.stdout.strip).to eq('unless-stopped')
    end

    # Test container port mapping
    it 'container has port 8080 exposed' do
        cmd = 'docker port phoenix-rtos-one 8080'
        @info[:vm].ssh(cmd).expect_success
    end

    # Test container volume mapping
    it 'container has data volume mounted' do
        cmd = 'docker inspect phoenix-rtos-one --format "{{range .Mounts}}{{.Source}}:{{.Destination}} {{end}}" | grep "/data:/data"'
        @info[:vm].ssh(cmd).expect_success
    end

    # Check if the service framework reports ready
    it 'checks oneapps motd' do
        cmd = 'cat /etc/motd'
        timeout_seconds = 60
        retry_interval_seconds = 5

        begin
            Timeout.timeout(timeout_seconds) do
                loop do
                    execution = @info[:vm].ssh(cmd)

                    if execution.exitstatus == 0 && execution.stdout.include?('All set and ready to serve')
                        expect(execution.exitstatus).to eq(0)
                        expect(execution.stdout).to include('All set and ready to serve')
                        break
                    else
                        sleep(retry_interval_seconds)
                    end
                end
            end
        rescue Timeout::Error
            fail "Timeout after #{timeout_seconds} seconds: MOTD did not contain 'All set and ready to serve'"
        end
    end

    # Cleanup: Stop container after tests
    after(:all) do
        if @info && @info[:vm]
            @info[:vm].ssh('docker stop phoenix-rtos-one || true')
            @info[:vm].ssh('docker rm phoenix-rtos-one || true')
        end
    end
end

