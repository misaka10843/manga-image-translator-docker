FROM pytorch/pytorch:2.11.0-cuda12.8-cudnn9-runtime

WORKDIR /app

COPY requirements.txt /app/requirements.txt

RUN export TZ=Etc/UTC \
    && apt-get update --yes \
    && apt-get install --yes --no-install-recommends \
       g++ wget ffmpeg libsm6 libxext6 gimp libvulkan1

RUN sed -i '/^torch$/d' /app/requirements.txt \
    && sed -i '/^torchvision$/d' /app/requirements.txt \
    && sed -i '/^torchaudio$/d' /app/requirements.txt

RUN pip install --no-cache-dir --break-system-packages -r /app/requirements.txt

RUN apt-get remove g++ wget --yes \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

COPY . /app

# Prepare models
RUN --mount=type=cache,target=/.cache/models \
    cp -rn /.cache/models/. /app/models/ || true && \
    python -u docker_prepare.py --continue-on-error && \
    cp -rn /app/models/. /.cache/models/ || true

RUN rm -rf /tmp && mkdir /tmp && chmod 1777 /tmp

ENV PYTHONPATH="/app"
WORKDIR /app
ENTRYPOINT ["python", "-m", "manga_translator"]
