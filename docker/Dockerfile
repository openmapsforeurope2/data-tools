FROM debian:10

RUN apt update
RUN apt install -y libpq-dev
RUN apt install -y python3
RUN apt install -y python3-pip

ENV APP_DIR_SRC=/usr/local/src/data-tools/                                              

WORKDIR $APP_DIR_SRC/../

COPY . $APP_DIR_SRC

WORKDIR $APP_DIR_SRC

RUN python3 -m pip install -r ./requirements.txt
