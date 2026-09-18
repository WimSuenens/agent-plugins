# Toolchain for the source-to-pptx skill.
#   potrace  - traces logos, maps and flat vector art out of a raster page
#   pypdfium2 - renders PDF pages without needing Poppler on the host
FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends potrace \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

WORKDIR /work
