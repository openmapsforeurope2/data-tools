FROM ubuntu:24.04 AS build

RUN apt update \
 && apt install -y libpq-dev \
 && apt install -y python3 \
 && apt install -y python3-pip \
 && rm -rf /var/lib/apt/lists/*
                                            
WORKDIR /usr/local/src/data-tools/  

COPY . .

RUN python3 -m pip install -r ./requirements.txt --break-system-packages

# ──────────────────────────────
# Image finale minimale
# ──────────────────────────────
FROM ubuntu:24.04

RUN apt update \
 && apt install -y python3 libpq5 \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/ /usr/local/

ENV APP_DIR_SRC=/usr/local/src/data-tools/

WORKDIR $APP_DIR_SRC