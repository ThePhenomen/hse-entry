FROM scratch

ADD myserver /myserver

ENTRYPOINT ["/myserver"]
CMD ["-h", "127.0.0.1", "-U", "postgres", "-P", "postgres", "-d", "postgres"]
