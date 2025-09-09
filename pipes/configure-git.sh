#!/bin/bash
git config user.email=justaneutral@gmail.com
git config user.name=justaneutral
git config --list --global
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/ssh-keys-ed25519-forjustaneutral


