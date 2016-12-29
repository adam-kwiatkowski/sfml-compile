#include "iostream"
#include "windows.h"

int main(int argc, char const *argv[]) {
  const char *path = argv[1];
  const char *exe = "\\compile";
  char finalCommand[256];
  strncpy(finalCommand, path, sizeof(finalCommand));
  strncat(finalCommand, exe, sizeof(finalCommand));
  std::cout << finalCommand << '\n';
  system(finalCommand);
  return 0;
}
