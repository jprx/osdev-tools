FROM ubuntu:24.04
ENV DEBIAN_FRONTEND "noninteractive"
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y build-essential git gcc bison flex texinfo wget libexpat-dev libncurses-dev python3 gawk
RUN mkdir -p /tool
COPY bootstrap.sh /tool
COPY redzone.patch /tool
USER root
WORKDIR /tool
RUN chmod +x /tool/bootstrap.sh && cd /tool && ./bootstrap.sh
RUN find /tool/cross/bin -type f -exec strip {} \;
RUN find /tool/cross/libexec -type f -exec strip {} \;
RUN rm -rf /tool/cross/share
RUN find /tool/cross/x86_64-elf/bin -type f -exec strip {} \;
RUN find /tool/cross/aarch64-elf/bin -type f -exec strip {} \;
RUN find /tool/cross/riscv64-elf/bin -type f -exec strip {} \;

FROM ubuntu:24.04
ENV DEBIAN_FRONTEND "noninteractive"
RUN apt-get update && apt-get upgrade -y && apt-get install -y libexpat-dev libncurses-dev bear less file xxd xorriso genext2fs
COPY --from=0 /tool/cross /tool/cross
ENV PATH="/tool/cross/bin:$PATH"
CMD ["/bin/bash"]
