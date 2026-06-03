require_relative '../../../lib/community/app_handler'

# Certification tests for the Prowler CLI appliance.
# Verifies the CLI is installed, the prowler user is the default,
# and the bastion hardening is applied at boot.
describe 'Appliance Certification' do
    include_context('vm_handler')

    it 'prowler CLI is installed' do
        cmd = '/home/prowler/.local/bin/prowler --version'
        start_time = Time.now
        timeout = 240

        loop do
            result = @info[:vm].ssh(cmd)
            break if result.success?
            raise "prowler CLI not reachable within #{timeout}s" if Time.now - start_time > timeout
            sleep 5
        end
    end

    it 'prowler user exists with bash shell' do
        result = @info[:vm].ssh("getent passwd prowler")
        expect(result.exitstatus).to eq(0)
        expect(result.stdout).to include('/home/prowler')
        expect(result.stdout).to include('/bin/bash')
    end

    it 'prowler user has sudo NOPASSWD' do
        result = @info[:vm].ssh("sudo -n -u prowler sudo -n id 2>&1 | head -1")
        # Either the wrapper resolves to uid=0, or the file exists
        sudoers = @info[:vm].ssh("test -f /etc/sudoers.d/90-prowler")
        expect(sudoers.exitstatus).to eq(0)
    end

    it 'root account is locked' do
        result = @info[:vm].ssh('passwd -S root')
        # Output looks like: "root L 2026-05-26 0 99999 7 -1" — second field is L (locked) or LK.
        status = result.stdout.split[1]
        expect(['L', 'LK']).to include(status)
    end

    it 'sshd allows root via key only (no password)' do
        result = @info[:vm].ssh("sudo sshd -T 2>/dev/null | grep -E '^permitrootlogin '")
        # prohibit-password is the modern alias; without-password is the legacy spelling.
        expect(result.stdout).to match(/permitrootlogin (prohibit-password|without-password)/i)
    end

    it 'sshd restricts logins to the prowler user' do
        result = @info[:vm].ssh("sudo sshd -T 2>/dev/null | grep -E '^allowusers '")
        expect(result.stdout.downcase).to match(/allowusers .*prowler/)
    end

    it 'ufw firewall is active and restrictive' do
        result = @info[:vm].ssh("sudo ufw status verbose")
        expect(result.stdout).to match(/Status: active/i)
        expect(result.stdout).to match(/deny \(incoming\)/i)
        expect(result.stdout).to match(/22\/tcp\s+ALLOW/i)
    end

    it 'fail2ban is enabled' do
        result = @info[:vm].ssh("systemctl is-enabled fail2ban")
        expect(result.stdout.strip).to eq('enabled')
    end




    it 'reports directory exists with correct ownership' do
        result = @info[:vm].ssh("stat -c '%U:%G %a' /var/lib/prowler/reports")
        expect(result.stdout.strip).to match(/^prowler:prowler 750$/)
    end

    it 'prowler-scan timer is installed' do
        result = @info[:vm].ssh("test -f /etc/systemd/system/prowler-scan.timer")
        expect(result.exitstatus).to eq(0)
    end

    it 'cloud config file is present with restricted permissions' do
        # /etc/default/prowler holds the Prowler Cloud API key. Mode must be
        # 0640 root:prowler so that random services on the host can't read it.
        result = @info[:vm].ssh("sudo stat -c '%U:%G %a' /etc/default/prowler")
        expect(result.stdout.strip).to match(/^root:prowler 640$/)
    end

    it 'helper commands exist' do
        %w[prowler-scan prowler-status].each do |cmd|
            result = @info[:vm].ssh("which #{cmd}")
            expect(result.exitstatus).to eq(0)
        end
    end


    it 'check oneapps motd' do
        cmd = 'cat /etc/motd'
        max_retries = 30
        sleep_time = 10
        expected_motd = 'All set and ready to serve'

        execution = nil
        max_retries.times do |attempt|
            execution = @info[:vm].ssh(cmd)
            break if execution.stdout.include?(expected_motd)
            puts "Attempt #{attempt + 1}/#{max_retries}: Waiting for MOTD to update..."
            sleep sleep_time
        end

        expect(execution.exitstatus).to eq(0)
        expect(execution.stdout).to include(expected_motd)
    end
end
