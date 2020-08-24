FROM swift:5.2

RUN apt-get -qq update && apt-get install -y \
  libssl-dev libxml2-dev zlib1g-dev tzdata \
  && rm -r /var/lib/apt/lists/*
