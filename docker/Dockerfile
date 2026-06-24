FROM ghcr.io/osgeo/gdal:ubuntu-small-latest

RUN apt-get update
RUN apt-get install -y libspatialindex-dev unar bc python3-pip python3-venv wget

ADD ./requirements.txt .
RUN python3 -m venv --system-site-packages /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN grep -v '^GDAL==' requirements.txt > requirements-docker.txt \
    && pip install --no-cache-dir -r requirements-docker.txt

RUN mkdir /code
ADD . /code/
RUN chmod +x /code/docker/entrypoint.sh

WORKDIR /code
ENTRYPOINT ["/code/docker/entrypoint.sh"]
CMD python3 server.py

EXPOSE 8080

EXPOSE 8443
