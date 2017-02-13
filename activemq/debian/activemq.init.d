#! /bin/sh
### BEGIN INIT INFO
# Provides:          activemq
# Required-Start:    $remote_fs
# Required-Stop:     $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: ActiveMQ instance
# Description:       Start ActiveMQ instance
### END INIT INFO

# Author: Damien Raude-Morvan <drazzib@debian.org>
# Author: Jonas Genannt <jonas.genannt@capi2name.de>
# Modified for Opencast use by Greg Logan <gregorydlogan@gmail.com>

PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="ActiveMQ instance"
NAME=activemq
DAEMON=/usr/bin/$NAME
SCRIPTNAME=/etc/init.d/`basename $0`
DEFAULT=/etc/default/$NAME
ACTIVEMQ_JAR=/usr/share/activemq/bin/run.jar
ACTIVEMQ_CONFIG_DIR=/etc/$NAME
ACTIVEMQ_PIDFILE=/var/run/activemq/$NAME.pid

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.2-14) to ensure that this file is present
# and status_of_proc is working.
. /lib/lsb/init-functions

# Whether to start ActiveMQ (as a daemon or not)
NO_START=0

ACTIVEMQ_USER=activemq

DIETIME=2

# Read configuration variable file if it is present
[ -r $DEFAULT ] && . $DEFAULT

# Exit now if daemon binary is not installed
test -x $DAEMON || exit 0

# Check that the user exists (if we set a user)
# Does the user exist?
if [ -n "$ACTIVEMQ_USER" ] ; then
    if getent passwd | grep -q "^$ACTIVEMQ_USER:"; then
        # Obtain the uid and gid
        DAEMONUID=`getent passwd |grep "^$ACTIVEMQ_USER:" | awk -F : '{print $3}'`
        DAEMONGID=`getent passwd |grep "^$ACTIVEMQ_USER:" | awk -F : '{print $4}'`
    else
        log_failure_msg "The user $ACTIVEMQ_USER, required to run $NAME does not exist."
        exit 1
    fi
fi

# Check whether startup has been disabled
if [ "$NO_START" != "0" -a "$1" != "stop" ]; then
        [ "$VERBOSE" != "no" ] && log_failure_msg "Not starting $NAME - edit /etc/default/$NAME and change NO_START to be 0 (or comment it out)."
        exit 0
fi

# Check if a given process pid's cmdline matches a given name
running_pid() {
    pid=$1
    [ -z "$pid" ] && return 1
    [ ! -d /proc/$pid ] &&  return 1
    cmd=`cat /proc/$pid/cmdline | tr "\000" "\n"|grep "activemq\.base" |cut -d= -f2`
    [ "x$cmd" != "x$INSTANCE" ] && return 1
    return 0
}

# Check if the process is running looking at /proc
# (works for all users)
running() {
    # No pidfile, probably no daemon present
    [ ! -f "$ACTIVEMQ_PIDFILE" ] && return 1
    pid=`cat $ACTIVEMQ_PIDFILE`
    running_pid $pid || return 1
    return 0
}

# Start the process using the wrapper
start_servers() {
        mkdir -p /var/run/activemq/
        chown $ACTIVEMQ_USER /var/run/activemq/

        export INSTANCE=/usr/share/activemq
        export ACTIVEMQ_USER
        export ACTIVEMQ_PIDFILE
        export ACTIVEMQ_HOME=/usr/share/activemq
        export ACTIVEMQ_CONFIG_DIR

        # Import global configuration
        . /usr/share/activemq/activemq-options
        # Import per instance configuration
        [ -r "${ACTIVEMQ_CONFIG_DIR}/options" ] && . ${ACTIVEMQ_CONFIG_DIR}/options

        log_progress_msg "$INSTANCE"

        start-stop-daemon --start --quiet --pidfile $ACTIVEMQ_PIDFILE \
                --chuid $ACTIVEMQ_USER --background \
                --name java --startas $DAEMON -- $ACTIVEMQ_ARGS

        errcode=$?
        if [ ! $errcode ]; then
                log_progress_msg "(failed)"
        else
                [ -n "$STARTTIME" ] && sleep $STARTTIME # Wait some time
                if running; then
                        log_progress_msg "(running)"
                else
                        log_progress_msg "(failed?)"
                fi
        fi
}


# Stops an running Instance
stop_server() {
	INSTANCE=$1

	start-stop-daemon --stop --quiet --pidfile $ACTIVEMQ_PIDFILE \
		--user $ACTIVEMQ_USER \
		--name java --startas $DAEMON -- stop
	if running; then
		force_stop
	fi
	if running; then
		log_progress_msg "(failed)"
	else
		log_progress_msg "(stopped)"
	fi
}

# Stop the process using the wrapper
stop_servers() {
        stop_server "$ACTIVEMQ_PIDFILE"
}

# Force the process to die killing it manually
force_stop() {
    [ ! -e "$ACTIVEMQ_PIDFILE" ] && return
    if running ; then
        kill -15 $pid
        # Is it really dead?
        sleep "$DIETIME"s
        if running ; then
            kill -9 $pid
            sleep "$DIETIME"s
            if running ; then
                echo "Cannot kill $NAME (pid=$pid)!"
                exit 1
            fi
        fi
    fi
    rm -f $ACTIVEMQ_PIDFILE
}


case "$1" in
  console)
        log_daemon_msg "Starting with Console $DESC "

        if [ -f $ACTIVEMQ_PIDFILE ]; then
                stop_server "$INSTANCE"
        fi

        export INSTANCE
        export ACTIVEMQ_USER
        export ACTIVEMQ_PIDFILE
        export ACTIVEMQ_HOME=/usr/share/activemq
        export ACTIVEMQ_CONFIG_DIR

        # Import global configuration
        . /usr/share/activemq/activemq-options
        # Import per instance configuration
        [ -r "${ACTIVEMQ_CONFIG_DIR}/options" ] && . ${ACTIVEMQ_CONFIG_DIR}/options

        ACTIVEMQ_ARGS=$(echo $ACTIVEMQ_ARGS | sed 's/start/console/')

        start-stop-daemon --start --pidfile $ACTIVEMQ_PIDFILE \
                --chuid $ACTIVEMQ_USER \
                --name java --startas $DAEMON -- $ACTIVEMQ_ARGS

        log_end_msg 0
	;;
  start)
        log_daemon_msg "Starting $DESC " "$NAME"
	start_servers
        log_end_msg 0
        ;;
  stop)
        log_daemon_msg "Stopping $DESC" "$NAME"
            stop_servers
            log_end_msg 0
        ;;
  restart|force-reload)
        log_daemon_msg "Restarting $DESC" "$NAME"
        stop_servers
        start_servers
        log_end_msg 0
        ;;
  status)
        log_daemon_msg "Checking status of $DESC" "$NAME"

        if running; then
                log_progress_msg "(running)"
        else
                log_progress_msg "(stopped)"
        fi

        log_end_msg 0
        ;;
  reload)
        log_warning_msg "Reloading $NAME daemon: not implemented, as the daemon"
        log_warning_msg "cannot re-read the config file (use restart)."
        ;;
  *)
        echo "Usage: $SCRIPTNAME {start|stop|restart|force-reload|status|console}" >&2
        exit 1
        ;;
esac

exit 0
