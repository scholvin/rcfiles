if [ -n "$BASH_VERSION" ]; then
  if [ "${BASH_VERSINFO[0]}" -gt "2" ]; then
    if [ -f "$HOME/.bashrc" ]; then
      source "$HOME/.bashrc"
    fi
  else
    echo "you have an ancient bash; godspeed"
  fi
fi

# export ENV variables as needed 

export OTHER=HELLO
export PROCPS_USERLEN=12

if [ -f ${HOME}/.profile.${HOSTNAME} ]; then
  source ${HOME}/.profile.${HOSTNAME}
fi
