#include <fcntl.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>

#define SYS_BUS_PCI_DEVICES "/sys/bus/pci/devices/"

int main(int argc, const char *argv[]) {
  if (argc != 2) {
    fprintf(stderr, "Usage: %s <bdf>\n", argv[0]);
    exit(1);
  }

  const char *bdf = argv[1];
  char path[256];

  snprintf(path, sizeof(path), SYS_BUS_PCI_DEVICES "%s/enable", bdf);
  int fd = open(path, O_RDWR | O_SYNC);
  if (fd == -1) {
    perror("open");
    exit(1);
  }
  const char *one = "1\n";
  write(fd, one, 2);
  close(fd);

  snprintf(path, sizeof(path), SYS_BUS_PCI_DEVICES "%s/resource0", bdf);
  size_t bar_size = 16 * 1024;
  fd = open(path, O_RDWR | O_SYNC);
  if (fd == -1) {
    perror("open");
    exit(1);
  }
  void *p = mmap(NULL, bar_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
  if (p == MAP_FAILED) {
    perror("mmap");
    exit(1);
  }

  volatile int *bar0 = (volatile int *)p;

  bar0[0] = 0xcafebabe;
  bar0[1] = 0xbadc0ffe;

  int a = bar0[0];
  int b = bar0[1];
  printf("bar[0]: 0x%x\n", a);
  printf("bar[1]: 0x%x\n", b);

  return 0;
}
