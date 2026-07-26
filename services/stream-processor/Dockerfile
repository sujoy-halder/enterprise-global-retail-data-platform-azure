FROM python:3.14-alpine@sha256:26730869004e2b9c4b9ad09cab8625e81d256d1ce97e72df5520e806b1709f92

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:$PATH"

RUN apk upgrade --no-cache \
    && addgroup -g 10001 retail \
    && adduser -D -u 10001 -G retail -h /home/retail retail \
    && python -m venv "$VIRTUAL_ENV"

WORKDIR /app
COPY pyproject.toml ./
COPY src ./src

RUN pip install --upgrade pip setuptools wheel \
    && pip install .

USER 10001:10001

ENTRYPOINT ["python", "-m", "retail_platform.stream_processor"]
