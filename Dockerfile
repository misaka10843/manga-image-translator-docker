FROM pytorch/pytorch:2.11.0-cuda12.8-cudnn9-runtime

WORKDIR /app

COPY requirements.txt /app/requirements.txt

RUN export TZ=Etc/UTC \
        && apt update --yes \
        && apt install g++ wget ffmpeg libsm6 libxext6 gimp libvulkan1 --yes \
        && wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb \
        && dpkg -i cuda-keyring_1.1-1_all.deb \
        && rm -f cuda-keyring_1.1-1_all.deb \
        && apt update --yes \
        && apt install -y libcudnn9-cuda-12 libcudnn9-dev-cuda-12 \
        && sed -i '/^torch$/d' /app/requirements.txt \
        && sed -i '/^torchvision$/d' /app/requirements.txt \
        && pip install --no-cache-dir numpy==1.26.4 \
        && pip install --no-cache-dir -r /app/requirements.txt \
        && apt remove g++ wget --yes \
        && apt autoremove --yes \
        && rm -rf /var/cache/apt

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
