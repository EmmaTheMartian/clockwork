#ifndef __ECHO_C__
#define __ECHO_C__

#include "echo.h"
#include <stdio.h>

void echo(const int word_count, const char **words) {
	for (int i = 0; i < word_count; i++)
		printf("%s\n", words[i]);
}

#endif
