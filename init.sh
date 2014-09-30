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

	if [ ! ~/${FILE} ]; then
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

if [ ! -L ~/.dotfiles ]; then
	echo "Setting up link ~/.dotfiles to ${ABSDIR}"
	ln -s ${ABSDIR} ~/.dotfiles
fi

bootstrap .zshrc "source ~/.dotfiles/.zshrc-global"
bootstrap .vimrc "source ~/.dotfiles/.vimrc-global"

