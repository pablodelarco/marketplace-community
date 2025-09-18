# frozen_string_literal: true

require 'rspec'

describe 'Docker Appliance Basic Tests' do
  before(:all) do
    @ip = ENV['TARGET_IP'] || '127.0.0.1'
    @ssh_key = ENV['SSH_KEY'] || '~/.ssh/id_rsa'
  end

  it 'should be accessible via SSH' do
    result = system("ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i #{@ssh_key} root@#{@ip} 'echo test' > /dev/null 2>&1")
    expect(result).to be true
  end

  it 'should have Docker service running' do
    result = system("ssh -o StrictHostKeyChecking=no -i #{@ssh_key} root@#{@ip} 'systemctl is-active docker' > /dev/null 2>&1")
    expect(result).to be true
  end

  it 'should have Docker container running' do
    result = system("ssh -o StrictHostKeyChecking=no -i #{@ssh_key} root@#{@ip} 'docker ps | grep -q redis-cache' > /dev/null 2>&1")
    expect(result).to be true
  end
end
