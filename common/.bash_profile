# ~/.bash_profile

# Source ~/.profile if it exists (environment variables)
if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

# Source ~/.bashrc for interactive settings (aliases, prompt, etc.)
if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
