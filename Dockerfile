
# FROM ubuntu:18.04
FROM perl:5-slim
LABEL maintainer="Dominique Besagni <dominique.besagni@inist.fr>"

# Install applications and set rights

COPY listeTermes.pl /usr/bin/listeTermes.pl
COPY limiteTermes.pl /usr/bin/limiteTermes.pl

RUN chmod 0755 /usr/bin/listeTermes.pl
RUN chmod 0755 /usr/bin/limiteTermes.pl
RUN ln -s /usr/bin/listeTermes.pl /usr/bin/listeTermes
RUN ln -s /usr/bin/limiteTermes.pl /usr/bin/limiteTermes

# Install necessary tools and clean up

ARG cpanm_args

RUN apt-get update \
    && apt-get install -y gcc libc6-dev make expat libexpat1-dev --no-install-recommends \
    && cpanm ${cpanm_args} Excel::Writer::XLSX \
    && cpanm ${cpanm_args} Excel::Writer::XLSX::Utility \
    && cpanm ${cpanm_args} Spreadsheet::Read \
    && cpanm ${cpanm_args} Spreadsheet::ParseXLSX \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && apt-get clean \
    && rm -fr /var/cache/apt/* /var/lib/apt/lists/* \
    && rm -fr ./cpanm /root/.cpanm /usr/src/* /tmp/*


WORKDIR /tmp
CMD ["/usr/bin/listeTermes.pl", "-h"]