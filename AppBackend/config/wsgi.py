import os
import logging
from django.core.wsgi import get_wsgi_application

logger = logging.getLogger('django')

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

logger.info("==== Starting FoodBalancer Backend Application ====")
logger.info(f"Environment: {os.environ.get('DJANGO_SETTINGS_MODULE')}")
logger.info(f"Python version: {os.sys.version}")

application = get_wsgi_application()
logger.info("Application initialized successfully")