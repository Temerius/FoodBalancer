# AppBackend/apps/core/middleware.py
import logging
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
            # Try to resolve the URL
            resolver_match = resolve(path)

            # Log details about the resolved URL
            logger.info(f"URL resolved to view: {resolver_match.view_name}")
            logger.info(f"URL app_name: {resolver_match.app_name}")
            logger.info(f"URL namespace: {resolver_match.namespace}")
            logger.info(f"URL URL name: {resolver_match.url_name}")
            logger.info(f"URL args: {resolver_match.args}")
            logger.info(f"URL kwargs: {resolver_match.kwargs}")
            logger.info(f"URL route: {resolver_match.route}")

            # Log information about the view function
            view_func = resolver_match.func
            logger.info(f"View function: {view_func}")
            if hasattr(view_func, 'view_class'):
                logger.info(f"View class: {view_func.view_class}")
                if hasattr(view_func.view_class, 'basename'):
                    logger.info(f"ViewSet basename: {view_func.view_class.basename}")

        except Exception as e:
            # Log the resolution failure
            logger.error(f"URL resolution failed for {path}: {str(e)}")

            # Let's check if it would match without a trailing slash
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

            # List available URL patterns for debugging
            from django.urls import get_resolver
            resolver = get_resolver()

            # Get all registered patterns
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

        # Log 404 responses with more details
        if response.status_code == 404:
            logger.error(f"404 Not Found: {request.method} {request.path_info}")

        return response