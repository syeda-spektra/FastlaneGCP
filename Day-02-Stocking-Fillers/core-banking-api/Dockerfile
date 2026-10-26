FROM python:3.12-slim
ENV PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY main.py core-banking-data.json ./
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app
