# First create the groups
sudo groupadd -f audio
sudo groupadd -f jackuser

# Then add user to the groups
sudo usermod -a -G audio,jackuser $USER

# Create/edit limits configuration file
sudo tee /etc/security/limits.d/99-realtime.conf << 'EOF'
@audio       -  rtprio     95
@audio       -  memlock    unlimited
@audio       -  nice       -19
@jackuser    -  rtprio     95
@jackuser    -  memlock    unlimited
@jackuser    -  nice       -19
# For PulseAudio and other processes
@audio       soft   memlock    unlimited
@audio       hard   memlock    unlimited
@audio       soft   rtprio     95
@audio       hard   rtprio     95
EOF

# Add specific memlock settings for current user
sudo tee /etc/security/limits.d/99-audio-$USER.conf << 'EOF'
$USER       soft   memlock    unlimited
$USER       hard   memlock    unlimited
EOF 