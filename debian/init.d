#!/bin/sh
### BEGIN INIT INFO
# Provides:          exaproxy
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: High performance non-caching proxy
# Description:       This program is a high-performance non-caching proxy.
# It is able to filter HTTP traffic using your favorite programming language.
# Potential use are :
#  + Non-caching HTTP/HTTPS (with CONNECT) Proxy
#      * forward, reverse or transparent proxy
#      * IPv6 and/or IPv4 support (can act as a 4to6 or 6to4 gateway)
#  + Traffic interception
#      * SQUID compatible interface
#      * ICAP like interface via local program
### END INIT INFO

# Author: Jean Baptiste Favre <jean-baptiste.favre@blablacar.com>

# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="non-caching proxy"
USER=exaproxy
NAME=exaproxy
DAEMON=/usr/sbin/exaproxy
DAEMON_ARGS=""
PIDFILE=/var/run/$NAME/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME

# Exit if the package is not installed
[ -x $DAEMON ] || exit 0

# Some env var the daemon will need
export ETC="/etc/exaproxy/"

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

if [ "$EXAPXYRUN" = "no" ]; then
	log_daemon_msg "You need to set EXAPXYRUN to yes in /etc/default/exaproxy in order to use this daemon."
	log_end_msg 0
fi

# Check that the RUNDIR exists, create it otherwise
RUNDIR=$(dirname ${PIDFILE})
[ ! -d ${RUNDIR} ] && mkdir -p ${RUNDIR} && chown exaproxy:exaproxy ${RUNDIR}

#
# Function that starts the daemon/service
#
do_start()
{
	if [ "$EXAPXYRUN" = "yes" ] || [ "$EXAPXYRUN" = "YES" ]; then
		CFG_COUNT=`cat /etc/exaproxy/exaproxy.conf | grep -v ^# | grep -v ^$ | wc -l`
		if [ $CFG_COUNT -lt 2 ] ; then
			log_warning_msg "WARNING: Empty configuration file. ExaProxy won't start"
			return 1
		else
			# Return
			#   0 if daemon has been started
			#   1 if daemon was already running
			#   2 if daemon could not be started
			# We create the PID file and we do background thanks to start-stop-daemon
			start-stop-daemon --start --quiet --pidfile $PIDFILE -c $USER -b -m --exec $DAEMON -- $DAEMON_OPTS
			return $?
		fi
        fi
}

#
# Function that stops the daemon/service
#
do_stop()
{
	if [ "$EXABPXYRUN" = "yes" ] || [ "$EXAPXYRUN" = "YES" ]; then
		# Return
		#   0 if daemon has been stopped
		#   1 if daemon was already stopped
		#   2 if daemon could not be stopped
		#   other if a failure occurred
		start-stop-daemon --stop --quiet --signal TERM --pidfile $PIDFILE -c $USER
		RETVAL="$?"
		sleep 1
		# clean stale PID file
		rm $PIDFILE 2> /dev/null
		[ "$RETVAL" = 2 ] && return 2
		# Wait for children to finish too if this is a daemon that forks
		# and if the daemon is only ever run from this initscript.
		# If the above conditions are not satisfied then add some other code
		# that waits for the process to drop all resources that could be
		# needed by services started subsequently.  A last resort is to
		# sleep for some time.
		start-stop-daemon --stop --quiet --oknodo --retry=0/30/KILL/5 --exec $DAEMON
		[ "$?" = 2 ] && return 2
		sleep 1
		return "$RETVAL"
	fi
}

#
# Function that sends a SIGUSR1 to the daemon/service
#
do_reload() {
	if [ "$EXAPXYRUN" = "yes" ] || [ "$EXAPXYRUN" = "YES" ]; then
		start-stop-daemon --stop --signal USR1 --quiet --pidfile $PIDFILE -c $USER
		return 0
	fi
}

do_force_reload() {
	if [ "$EXAPXYRUN" = "yes" ] || [ "$EXAPXYRUN" = "YES" ]; then
		start-stop-daemon --stop --signal USR2 --quiet --pidfile $PIDFILE -c $USER
		return 0
	fi
}

case "$1" in
  start)
	start-stop-daemon --status --quiet --pidfile $PIDFILE -c $USER
	retval=$?
	if [ $retval -eq 0 ] ; then
		log_warning_msg "$NAME is already running"
		log_end_msg 1
	else
		log_daemon_msg "Starting $DESC" "$NAME "
		do_start
		case "$?" in
			0|1) log_end_msg 0 ;;
			2) log_end_msg 1 ;;
		esac
	fi
	;;
  stop)
	log_daemon_msg "Stopping $DESC" "$NAME "
	do_stop
	case "$?" in
		0) log_end_msg 0 ;;
		1|2) log_end_msg 1 ;;
	esac
	;;
  status)
	status_of_proc -p "$PIDFILE" "$DAEMON" "$NAME" && exit 0 || exit $?
        ;;
  reload)
	log_daemon_msg "Reloading $DESC" "$NAME "
	do_reload
	log_end_msg $?
	;;
  force-reload)
	log_daemon_msg "Reloading $DESC (and subprocesses)" "$NAME "
	do_force_reload
	log_end_msg $?
	;;
  restart)
	log_daemon_msg "Restarting $DESC" "$NAME "
	do_stop
	case "$?" in
	  0|1)
		do_start
		case "$?" in
			0) log_end_msg 0 ;;
			1) log_end_msg 1 ;; # Old process is still running
			*) log_end_msg 1 ;; # Failed to start
		esac
		;;
	  *)
	  	# Failed to stop
		log_end_msg 1
		;;
	esac
	;;
  *)
	log_warning_msg "Usage: $SCRIPTNAME {start|stop|restart|reload|force-reload|status}"
	log_end_msg 3
	exit 3
	;;
esac

exit 0
