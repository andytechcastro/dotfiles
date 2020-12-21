alias gstatus="git status"
alias gadd="git add"
alias gcommit="git commit -m"
alias gpush="git push origin"
alias gcheck="git checkout"
alias gpull="git pull origin"
alias home="cd ~"
alias gbranch="git branch"
alias ranger='ranger --choosedir=$HOME/.rangerdir; LASTDIR=`cat $HOME/.rangerdir`; cd "$LASTDIR"'

alias backuphome='rsync -avh --exclude ".npm" --exclude ".local" --exclude ".cache" --exclude ".config/google-chrome" --exclude ".mozilla" --exclude ".kube" --exclude ".java" --exclude ".fnmt" --exclude ".steam" /home/andres /mnt/backup --delete'
