#! /bin/sh

set -e

DAEMON=/usr/local/bin/cudaminer
CUDAMINER_OPTS=''
CUDAMINER_DEFAULTS_FILE=/etc/default/cudaminer
CUDAMINER_PID_FILE=/var/run/cudaminer.pid

test -x $DAEMON || exit 0

. /lib/lsb/init-functions

if [ -s $CUDAMINER_DEFAULTS_FILE ]; then
    . $CUDAMINER_DEFAULTS_FILE
fi

cudaminer_start() {
    if start-stop-daemon --start --quiet --background \
        --pidfile $CUDAMINER_PID_FILE --make-pidfile \
        --exec $DAEMON -- -S $CUDAMINER_OPTS
    then
        rc=0
        sleep 1
        if ! kill -0 $(cat $CUDAMINER_PID_FILE) >/dev/null 2>&1; then
            log_failure_msg "cudaminer failed to start"
            rc=1
        fi
    else
        rc=1
    fi
    if [ $rc -eq 0 ]; then
        log_end_msg 0
    else
        log_end_msg 1
        rm -f $CUDAMINER_PID_FILE
    fi
}


case "$1" in
  start)
        cudaminer_start
	;;
  stop)
	log_daemon_msg "Stopping cudaminer" "cudaminer"
	start-stop-daemon --stop --quiet --oknodo --pidfile $CUDAMINER_PID_FILE
	log_end_msg $?
	rm -f $CUDAMINER_PID_FILE
	;;

  restart)
	set +e
	log_daemon_msg "Restarting rsync daemon" "rsync"
	if [ -s $CUDAMINER_PID_FILE ] && kill -0 $(cat $CUDAMINER_PID_FILE) >/dev/null 2>&1; then
	    start-stop-daemon --stop --quiet --oknodo --pidfile $CUDAMINER_PID_FILE || true
	    sleep 1
	else
    	    log_warning_msg "cudaminer not running, attempting to start."
    	    rm -f $CUDAMINER_PID_FILE
	fi
        cudaminer_start
	;;

  status)
	status_of_proc -p $CUDAMINER_PID_FILE "$DAEMON" cudaminer
	exit $?	# notreached due to set -e
	;;
  *)
	echo "Usage: /etc/init.d/cudaminer {start|stop|restart|status}"
	exit 1
esac

exit 0
