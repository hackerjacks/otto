SRC_FILES = $(wildcard *.ml*)

test:
	ocamlbuild -lflags "-warn-error +a" -cflags "-warn-error +a -thread" -libs threads -pkgs oUnit,yojson,str,ZMQ,unix,threads test_main.byte ; ./test_main.byte

server:
	ocamlbuild -lflags "-warn-error +a" -cflags "-warn-error +a -thread -g" -libs threads -pkgs oUnit,yojson,str,ZMQ,unix,threads otto_server.byte

clean:
	ocamlbuild -clean
