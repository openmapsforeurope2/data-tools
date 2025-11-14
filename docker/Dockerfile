FROM ubuntu:24.04

RUN apt update \
 && apt install -y libpq-dev \
 && apt install -y python3 \
 && apt install -y python3-pip \
 && rm -rf /var/lib/apt/lists/*

ENV APP_DIR_SRC=/usr/local/src/data-tools/                                              

WORKDIR $APP_DIR_SRC/../

COPY . $APP_DIR_SRC

WORKDIR $APP_DIR_SRC

RUN python3 -m pip install -r ./requirements.txt --break-system-packages