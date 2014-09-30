#!/bin/sh

bootstrap() {
	FILE=$1
	CONTENT=$2

	if [ ! ~/${FILE} ]; then
		echo $CONTENT > ~/${FILE}
	else
		echo "Ensure ~/${FILE} contains the following: "
		echo "--------"
		echo $CONTENT
		echo "--------"
		echo
	fi
}

bootstrap .zshrc "source ~/.dotfiles/.zshrc-global"
bootstrap .vimrc "source ~/.dotfiles/.vimrc-global"

