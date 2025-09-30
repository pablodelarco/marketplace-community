# 🚀 OpenNebula Appliance Creation Tutorials

**Create OpenNebula marketplace appliances from Docker containers**

This guide provides two approaches for creating OpenNebula appliances:

---

## 📚 Choose Your Approach

### 🤖 Automatic Approach (Recommended)

**Best for:** Quick appliance creation, beginners, standard Docker containers

**Time:** 5 minutes

**What you do:**
1. Create a simple `.env` configuration file with your Docker container details
2. Run the generator script
3. Done! All 13+ files are generated automatically

**👉 [Go to Automatic Tutorial](automatic-appliance-tutorial/README.md)**

**Example:**
```bash
# Create config file
cat > nginx.env << 'ENVEOF'
DOCKER_IMAGE="nginx:alpine"
APPLIANCE_NAME="nginx"
APP_NAME="NGINX Web Server"
PUBLISHER_NAME="Your Name"
PUBLISHER_EMAIL="your.email@example.com"
DEFAULT_PORTS="80:80,443:443"
WEB_INTERFACE="true"
ENVEOF

# Run generator
./generate-docker-appliance.sh nginx.env

# Done! All files created automatically
```

---

### ✍️ Manual Approach

**Best for:** Custom appliances, advanced users, special requirements

**Time:** 30-45 minutes

**What you do:**
1. Manually create each file (metadata.yaml, appliance.sh, README.md, etc.)
2. Write custom installation scripts
3. Configure Packer build files
4. Create test files

**👉 [Go to Manual Tutorial](manual-appliance-tutorial/README.md)**

---

## 🤔 Which Approach Should I Use?

### Use **Automatic Approach** if:
- ✅ You want to create an appliance quickly
- ✅ Your Docker container is straightforward
- ✅ You're new to OpenNebula appliances
- ✅ You want to follow best practices automatically

### Use **Manual Approach** if:
- ✅ You need custom installation logic
- ✅ You want full control over every file
- ✅ Your appliance has special requirements
- ✅ You're an advanced user

---

## 💡 Recommendation

**Start with the Automatic Approach!**

Even if you plan to customize heavily, starting with the generator gives you:
1. A working baseline
2. Correct file structure
3. Best practices implemented
4. Files you can then customize

---

## 📖 Additional Resources

- [OpenNebula Documentation](https://docs.opennebula.io/)
- [Docker Hub](https://hub.docker.com/)
- [Packer Documentation](https://www.packer.io/docs)
- [OpenNebula Marketplace](https://marketplace.opennebula.io/)
