obj-m += snd-soc-wm8960.o
snd-soc-wm8960-objs := wm8960.o

KDIR ?= /home/orangepi/kernel-src

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
