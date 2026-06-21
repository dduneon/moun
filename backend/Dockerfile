FROM python:3.12-slim

WORKDIR /app

COPY pyproject.toml .
RUN pip install --no-cache-dir .

COPY app/ app/
COPY alembic/ alembic/
COPY alembic.ini .
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

EXPOSE 4020

ENTRYPOINT ["./entrypoint.sh"]
