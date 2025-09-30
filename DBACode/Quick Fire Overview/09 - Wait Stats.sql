-- Red flag: High CXPACKET, PAGEIOLATCH, WRITELOG waits.

-- Top waits (ignoring benign ones)
SELECT TOP 20   wait_type
,               wait_time_ms / 1000.0           AS WaitTimeSec
,               signal_wait_time_ms / 1000.0    AS SignalWaitSec
,				waiting_tasks_count
FROM			sys.dm_os_wait_stats
WHERE			wait_type NOT IN ('SLEEP_TASK','BROKER_TASK_STOP','XE_TIMER_EVENT','XE_DISPATCHER_WAIT')
ORDER BY		wait_time_ms DESC;