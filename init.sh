#!/bin/sh


if [ -L $0 ] ; then
	DIR=$(dirname $(readlink -f $0))
else
	DIR=$(dirname $0)
fi 
ABSDIR=$(cd "$DIR"; pwd)

bootstrap() {
	FILE=$1
	CONTENT=$2

	if [ ! -f ~/${FILE} ]; then
		echo $CONTENT > ~/${FILE}
	else
		echo 
		echo "Ensure ~/${FILE} contains the following: "
		echo "--------"
		echo $CONTENT
		echo "--------"
		echo
	fi
}

if [ ! -L ~/.dotfiles ] && [ ! -d ~/.dotfiles ] ; then
	echo "Setting up link ~/.dotfiles to ${ABSDIR}"
	ln -s ${ABSDIR} ~/.dotfiles
fi

mkdir -p ~/.vim/info

bootstrap .zshrc "source ${ABSDIR}/.zshrc-global"
bootstrap .vimrc "source ${ABSDIR}/.vimrc-global"
bootstrap .tmux.conf "source-file ${ABSDIR}/.tmux-global.conf"

