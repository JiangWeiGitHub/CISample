FROM ubuntu:14.04

MAINTAINER JiangWeiGitHub <wei.jiang@winsuntech.cn>

# update apt
RUN apt-get update

# install essential packages with apt-get
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y vsftpd

# modify /etc/vsftpd.conf
RUN sed 's/anonymous_enable=NO/anonymous_enable=YES/' -i /etc/vsftpd.conf \
 && sed 's/#write_enable=YES/write_enable=YES/' -i /etc/vsftpd.conf

EXPOSE 20/tcp 21/tcp

CMD ["top"]
