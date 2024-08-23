#include <stdio.h>

int main(const int argc, const char** argv) {
	for (int i = 0; i < argc; i++)
		printf("%s\n", argv[i]);
	return 0;
}
