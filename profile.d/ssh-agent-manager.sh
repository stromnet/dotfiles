# Purpose: on SSH login, check for SSH_AUTH_SOCK and setup an alterative static symlink.
# This is then used inside tmux sessions to avoid loss of socket on re-attach
#
# This script should be sourced in .zsrc:
# [ -z $TMUX ] && source ~/profile.d/sshagent.sh
#
# Make sure .tmux.conf have the proper lines as well (see ../.tmux-global.conf)

export SSH_AUTH_SOCK_LINK="/tmp/ssh-$USER/agent"

DEBUG=${SSH_AGENT_MGR_DEBUG:-0}
function debug() {
	[ $DEBUG != 0 ] && echo "ssh-agent-manager: $*"
}

# Ensure directory exists
DIR=$(dirname $SSH_AUTH_SOCK_LINK)
mkdir -p "$DIR"
chmod go= "$DIR"

if [ -L $SSH_AUTH_SOCK_LINK ]; then
	LINK_TGT=$(readlink $SSH_AUTH_SOCK_LINK)
	if [[ ( $? != 0 || ! -r $LINK_TGT ) ]]; then;
		# Kill link
		debug "Existing link ${SSH_AUTH_SOCK_LINK} is dead, removing"
		rm -f ${SSH_AUTH_SOCK_LINK}
		unset LINK_TGT
	fi
fi

if [ "$SSH_AUTH_SOCK" != "" ] && [ -r $SSH_AUTH_SOCK ]; then
	debug "Setting up ${SSH_AUTH_SOCK} as prioritized link ${SSH_AUTH_SOCK_LINK}"

	if [ ! -z ${LINK_TGT} ]; then
		# A link already exist.
		# Find a free ID to stash it
		N=0
		while [ $N -lt 10 ]; do 
			if [ ! -L ${SSH_AUTH_SOCK_LINK}.${N} ]; then
				# XXX: If we get a free slot we will be undordered!
				break
			fi
			N=$(($N+1))
		done

		debug "Stashing ${LINK_TGT} as ${SSH_AUTH_SOCK_LINK}.${N}"
		mv ${SSH_AUTH_SOCK_LINK} ${SSH_AUTH_SOCK_LINK}.${N}
	fi

	debug "Pointing link ${SSH_AUTH_SOCK_LINK} to ${SSH_AUTH_SOCK}"
	ln -sfn ${SSH_AUTH_SOCK} ${SSH_AUTH_SOCK_LINK}

	# Setup a cleanup function
	function zshexit() {
		# Is the current link our link?
		LINK_TGT=$(readlink ${SSH_AUTH_SOCK_LINK})

		if [ ${LINK_TGT} = ${SSH_AUTH_SOCK} ]; then
			debug "We are no longer current agent, removing ${SSH_AUTH_SOCK_LINK}"
			rm -f ${SSH_AUTH_SOCK_LINK}
			REPLACE_LINK=1
		fi

		# Check if we have alterantive ones, always go for the last one
		N=0
		while [ $N -lt 10 ]; do 
			LINK=${SSH_AUTH_SOCK_LINK}.${N}

			if [ -L ${LINK} ]; then
				LINK_TGT=$(readlink ${LINK})
				if [ ${LINK_TGT} = ${SSH_AUTH_SOCK} ]; then
					debug "We are no longer avialable, remove from list of previous links"
					# Our link; kill it
					rm -f ${LINK}
				else
					LAST_VALID_LINK=${LINK}
				fi
			fi
			N=$(($N+1))
		done

		if [ ! -z $REPLACE_LINK ]; then
			if [ ! -z ${LAST_VALID_LINK} ]; then
				LINK_TGT=$(readlink ${LAST_VALID_LINK})
				debug "Re-instanting ${LAST_VALID_LINK} ($LINK_TGT) as current socket-link"
				mv ${LAST_VALID_LINK} ${SSH_AUTH_SOCK_LINK}
			fi
		fi

		# renumber links to get proper order
		N=0
		NEXT_ID=0
		while [ $N -lt 10 ]; do 
			LINK=${SSH_AUTH_SOCK_LINK}.${N}

			if [ -L ${LINK} ]; then
				if [ $N != $NEXT_ID ]; then
					NEW_LINK=${SSH_AUTH_SOCK_LINK}.${NEXT_ID}
					debug "Renumering ${LINK} as ${NEW_LINK}"
					mv ${LINK} ${NEW_LINK}

					NEXT_ID=$(($NEXT_ID+1))
				fi
			fi
			N=$(($N+1))
		done
	}
fi

