
import logging
import json
from datetime import datetime


class CustomJsonFormatter(logging.Formatter):
    """
    Форматировщик логов в JSON формате для улучшения анализа.
    """

    def format(self, record):
        """
        Форматирует запись лога в структурированный JSON.
        """
        log_record = {
            'timestamp': datetime.fromtimestamp(record.created).isoformat(),
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'module': record.module,
            'process': record.process,
            'thread': record.thread,
        }

        
        if record.exc_info:
            log_record['exception'] = {
                'type': record.exc_info[0].__name__,
                'message': str(record.exc_info[1]),
            }

        
        if hasattr(record, 'status_code'):
            log_record['status_code'] = record.status_code

        if hasattr(record, 'user_id'):
            log_record['user_id'] = record.user_id

        if hasattr(record, 'ip'):
            log_record['ip'] = record.ip

        if hasattr(record, 'duration'):
            log_record['duration_ms'] = record.duration

        
        return json.dumps(log_record)