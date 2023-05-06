# (to be sourced by $HOME/.bashrc - if "in test mode", set the appropriate
# env var; and then source ./.env - to reset aliases and functions.)
if [ -e ./.testmode ]; then
    export STODO_CONFIG_PATH=$PWD/test/config
fi
. ./.env
