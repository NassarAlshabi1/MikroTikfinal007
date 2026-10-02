FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl unzip xz-utils zip \
    libglu1-mesa wget file \
    openjdk-17-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV FLUTTER_ROOT=/opt/flutter
ENV PATH="${FLUTTER_ROOT}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"


ENV PUB_CACHE=/root/.pub-cache
ENV GRADLE_USER_HOME=/root/.gradle

RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    curl -fsSL https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
         -o /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools && \
    mv /tmp/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip


RUN yes | sdkmanager --licenses > /dev/null && \
    sdkmanager \
        "platform-tools" \
        "platforms;android-35" \
        "build-tools;35.0.0"

RUN git clone --depth 1 --branch 3.27.2 \
        https://github.com/flutter/flutter.git ${FLUTTER_ROOT} && \
    flutter precache --android && \
    flutter config --no-analytics && \
    flutter config --android-sdk ${ANDROID_SDK_ROOT}

WORKDIR /app
COPY . .

RUN echo "sdk.dir=${ANDROID_SDK_ROOT}" > android/local.properties && \
    echo "flutter.sdk=${FLUTTER_ROOT}" >> android/local.properties


RUN flutter pub get

CMD ["flutter", "build", "apk", "--release"]
