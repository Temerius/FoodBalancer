
import logging
import time
from django.urls import resolve
from django.utils.deprecation import MiddlewareMixin
from django.conf import settings

logger = logging.getLogger('django.request')


class URLDebugMiddleware(MiddlewareMixin):
    """
    Middleware to log detailed URL resolution information.
    """

    def process_request(self, request):
        """Log URL resolution details for each request."""
        path = request.path_info
        logger.info(f"Received request: {request.method} {path}")

        try:
            
            resolver_match = resolve(path)

            
            logger.info(f"URL resolved to view: {resolver_match.view_name}")
            logger.info(f"URL app_name: {resolver_match.app_name}")
            logger.info(f"URL namespace: {resolver_match.namespace}")
            logger.info(f"URL URL name: {resolver_match.url_name}")
            logger.info(f"URL args: {resolver_match.args}")
            logger.info(f"URL kwargs: {resolver_match.kwargs}")
            logger.info(f"URL route: {resolver_match.route}")

            
            view_func = resolver_match.func
            logger.info(f"View function: {view_func}")
            if hasattr(view_func, 'view_class'):
                logger.info(f"View class: {view_func.view_class}")
                if hasattr(view_func.view_class, 'basename'):
                    logger.info(f"ViewSet basename: {view_func.view_class.basename}")

        except Exception as e:
            
            logger.error(f"URL resolution failed for {path}: {str(e)}")

            
            if path.endswith('/'):
                try:
                    no_slash_path = path[:-1]
                    alt_resolver_match = resolve(no_slash_path)
                    logger.info(f"URL would resolve without trailing slash to: {alt_resolver_match.view_name}")
                except:
                    pass
            else:
                try:
                    with_slash_path = f"{path}/"
                    alt_resolver_match = resolve(with_slash_path)
                    logger.info(f"URL would resolve with trailing slash to: {alt_resolver_match.view_name}")
                except:
                    pass

            
            from django.urls import get_resolver
            resolver = get_resolver()

            
            all_patterns = []

            def collect_patterns(resolver, prefix=''):
                for pattern in resolver.url_patterns:
                    if hasattr(pattern, 'pattern'):
                        pattern_str = str(pattern.pattern)
                        if hasattr(pattern, 'lookup_str'):
                            lookup_str = pattern.lookup_str
                            all_patterns.append(f"{prefix}{pattern_str} -> {lookup_str}")
                        elif hasattr(pattern, 'callback') and pattern.callback:
                            callback_name = pattern.callback.__name__
                            all_patterns.append(f"{prefix}{pattern_str} -> {callback_name}")
                        else:
                            all_patterns.append(f"{prefix}{pattern_str}")

                        if hasattr(pattern, 'url_patterns'):
                            collect_patterns(pattern, prefix=f"{prefix}{pattern_str}")

            collect_patterns(resolver)
            logger.info(f"Available URL patterns:")
            for pattern in all_patterns:
                logger.info(f"  {pattern}")

        return None

    def process_response(self, request, response):
        """Log response status for each request."""
        logger.info(f"Response: {response.status_code} for {request.method} {request.path_info}")

        
        if response.status_code == 404:
            logger.error(f"404 Not Found: {request.method} {request.path_info}")

        return response


class PerformanceLoggingMiddleware(MiddlewareMixin):
    """
    Middleware для измерения времени выполнения запросов.
    """

    def process_request(self, request):
        """Засекаем время начала обработки запроса"""
        request._start_time = time.time()
        return None

    def process_response(self, request, response):
        """Логируем время выполнения запроса"""
        
        if hasattr(request, '_start_time'):
            
            duration = time.time() - request._start_time

            
            user_id = 'anonymous'
            if hasattr(request, 'user') and request.user.is_authenticated:
                user_id = request.user.usr_id

            
            path = request.path_info
            method = request.method
            status_code = response.status_code

            
            log_message = f"Request {method} {path} completed in {duration:.2f}s with status {status_code} for user_id={user_id}"

            performance_logger = logging.getLogger('app.performance')

            if duration > 1.0 or status_code >= 500:
                
                performance_logger.warning(log_message)
            elif status_code >= 400 or duration > 0.5:
                
                performance_logger.info(log_message)
            else:
                
                performance_logger.debug(log_message)

        return response


class ExceptionLoggingMiddleware(MiddlewareMixin):
    """
    Middleware для детального логирования исключений.
    """

    def process_exception(self, request, exception):
        """
        Логирование исключений, возникающих при обработке запросов.
        """
        logger = logging.getLogger('django.request')

        
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')

        
        user_id = 'anonymous'
        if hasattr(request, 'user') and request.user.is_authenticated:
            user_id = request.user.usr_id

        
        logger.error(
            f"Exception in {request.method} {request.path}: "
            f"{exception.__class__.__name__}: {str(exception)}, "
            f"user_id={user_id}, ip={ip}",
            exc_info=True,
            extra={
                'status_code': 500,
                'request': request,
                'user_id': user_id,
                'ip': ip,
                'method': request.method,
                'path': request.path,
            }
        )

        
        return None