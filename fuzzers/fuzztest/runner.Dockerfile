FROM gcr.io/fuzzbench/base-image           # Base image (Ubuntu 20.04).

#Maybe antlr4?
RUN apt-get update                     # Install any runtime dependencies for your fuzzer.
