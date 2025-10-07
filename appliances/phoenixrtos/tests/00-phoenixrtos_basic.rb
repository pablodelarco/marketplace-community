require_relative '../../../lib/community/app_handler'

describe 'Phoenix RTOS Development Environment Appliance' do
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
        cmd = 'docker images --format "table {{.Repository}}:{{.Tag}}" | grep "pablodelarco/phoenix-rtos-one:latest"'
        @info[:vm].ssh(cmd).expect_success
    end

    # Test helper script is installed
    it 'phoenix-rtos helper script is installed' do
        cmd = 'test -x /usr/local/bin/phoenix-rtos'
        @info[:vm].ssh(cmd).expect_success
    end

    # Test container service is configured
    it 'phoenix-rtos container service is configured' do
        cmd = 'systemctl list-unit-files | grep phoenix-rtos-container'
        @info[:vm].ssh(cmd).expect_success
    end

    # Test development tools are installed
    it 'development tools are installed' do
        tools = ['git', 'vim', 'curl', 'wget', 'python3']
        tools.each do |tool|
            cmd = "which #{tool}"
            @info[:vm].ssh(cmd).expect_success
        end
    end

    # Test container can be started
    it 'phoenix rtos container can be started' do
        # Start the container
        cmd = 'systemctl start phoenix-rtos-container'
        @info[:vm].ssh(cmd).expect_success
        
        # Wait a moment for container to start
        sleep 5
        
        # Check if container is running
        cmd = 'docker ps --format "table {{.Names}}" | grep phoenix-rtos-dev'
        @info[:vm].ssh(cmd).expect_success
        
        # Test container is responsive
        cmd = 'docker exec phoenix-rtos-dev echo "Container is running"'
        execution = @info[:vm].ssh(cmd)
        expect(execution.success?).to be(true)
        expect(execution.stdout.strip).to eq('Container is running')
    end

    # Test helper script functionality
    it 'phoenix-rtos helper script works' do
        # Test status command
        cmd = 'phoenix-rtos status'
        @info[:vm].ssh(cmd).expect_success
        
        # Test logs command
        cmd = 'phoenix-rtos logs'
        @info[:vm].ssh(cmd).expect_success
    end

    # Test working directory is created
    it 'phoenix rtos working directory exists' do
        work_dir = APP_CONTEXT_PARAMS[:PHOENIX_WORK_DIR] || '/opt/phoenix-rtos'
        cmd = "test -d #{work_dir}"
        @info[:vm].ssh(cmd).expect_success
    end

    # Test configuration files are created
    it 'configuration files are created' do
        cmd = 'test -f /etc/phoenix-rtos/container.conf'
        @info[:vm].ssh(cmd).expect_success
        
        cmd = 'test -f /etc/docker/daemon.json'
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

    # Test container auto-start functionality
    it 'container auto-start is configured correctly' do
        auto_start = APP_CONTEXT_PARAMS[:PHOENIX_AUTO_START] || 'YES'
        
        if auto_start.upcase == 'YES'
            # Check if service is enabled
            cmd = 'systemctl is-enabled phoenix-rtos-container'
            @info[:vm].ssh(cmd).expect_success
        end
    end

    # Test exposed ports configuration
    it 'exposed ports are configured' do
        expose_ports = APP_CONTEXT_PARAMS[:PHOENIX_EXPOSE_PORTS] || '22,80,443'
        
        unless expose_ports.empty?
            # Check if container has port mappings
            cmd = 'docker port phoenix-rtos-dev'
            execution = @info[:vm].ssh(cmd)
            
            # Should have some port mappings if ports are exposed
            expect(execution.success?).to be(true)
        end
    end

    # Cleanup: Stop container after tests
    after(:all) do
        if @info && @info[:vm]
            @info[:vm].ssh('systemctl stop phoenix-rtos-container || true')
            @info[:vm].ssh('docker stop phoenix-rtos-dev || true')
            @info[:vm].ssh('docker rm phoenix-rtos-dev || true')
        end
    end
end

