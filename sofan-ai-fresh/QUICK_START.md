# ⚡ Quick Start Guide

Get your Sofan AI WebUI running in **5 minutes**!

---

## 🖥️ Local Development (Laptop/Desktop)

### 1. Clone Repository
```bash
git clone https://github.com/sofan1/Sofan-AI.git
cd Sofan-AI
chmod +x *.sh
```

### 2. Run Setup
```bash
bash deploy/remote-setup.sh
```

### 3. Set API Key
```bash
export GEMINI_API_KEY="your-api-key-here"
```

### 4. Start Dashboard
```bash
./Hermes-Start.sh dashboard
```

### 5. Open in Browser
```
http://localhost:9119
```

✅ **Done!** Your AI Dashboard is running locally.

---

## 🌐 Cloud Deployment (Server)

### 1. SSH into Server
```bash
ssh user@your-server-ip
cd ~
```

### 2. Clone & Setup
```bash
git clone https://github.com/sofan1/Sofan-AI.git
cd Sofan-AI
bash deploy/remote-setup.sh
```

### 3. Configure Domain
```bash
# For domain: sofan-ai.space-z.ai
sudo cp deploy/nginx.conf /etc/nginx/sites-available/sofan-ai
sudo ln -s /etc/nginx/sites-available/sofan-ai /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 4. Get SSL Certificate
```bash
sudo certbot certonly --standalone -d sofan-ai.space-z.ai
```

### 5. Start Services
```bash
./Hermes-Start.sh service install
./Hermes-Start.sh service status
```

### 6. Access Online
```
https://sofan-ai.space-z.ai
```

✅ **Done!** Your AI WebUI is live on the internet!

---

## 📱 Optional: Pair WhatsApp

```bash
./Hermes-Start.sh qr-pair
```

Scan the QR code with WhatsApp on your phone.

---

## 🔍 Monitor Your System

```bash
# Check status
./Hermes-Start.sh service status

# View logs
./Hermes-Start.sh service logs

# Restart services
./Hermes-Start.sh service restart
```

---

## 🆘 Need Help?

**Dashboard not loading?**
```bash
lsof -i :9119        # Check if port is in use
./Hermes-Start.sh dashboard --verbose
```

**SSL certificate issues?**
```bash
sudo certbot renew --force-renewal
sudo systemctl reload nginx
```

**Check all logs:**
```bash
journalctl --user -u hermes-dashboard -f
journalctl --user -u hermes-webhook -f
```

---

## 📚 Full Documentation

- [README.md](./README.md) - Complete overview
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Detailed deployment guide
- GitHub Issues: [Report problems](https://github.com/sofan1/Sofan-AI/issues)

---

## 🎯 Next Steps

1. ✅ **Local**: Run dashboard locally
2. 🌍 **Cloud**: Deploy to server
3. 💬 **WhatsApp**: Pair your business account
4. 🔧 **Configure**: Edit `~/.hermes/config.yaml`
5. 📊 **Monitor**: Check logs regularly

---

**Questions?** Open an issue on GitHub! 🚀
