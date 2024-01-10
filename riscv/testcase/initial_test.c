#include "io.h"
//input: 1 2 3 4

int a[4];
int main()
{
	int i;
    for (i = 0; i < 4; i++)
	{
		a[i] = 0;
	}
	for (i = 0; i < 4; i++)
	{
		outl(a[i]);
	}
}
