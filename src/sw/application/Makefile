CFLAGS = -fPIC
LDFLAGS = -lfpga

SRCS=$(wildcard *.c)
OBJS=$(SRCS:.c=.o)

all: $(OBJS)

test:
	for blocks in 1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384; \
	do \
		data=`wcalc -q $$blocks*1024`; \
		./$$file $$data > $$file.csv; \
	done

clean:
	rm $(OBJS)
