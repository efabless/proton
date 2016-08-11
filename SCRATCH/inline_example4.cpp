
#include <stdlib.h>
#include <stdio.h>

int main()
{
      char *env = getenv("PATH");
      if (env)
            printf("value of PATH is: %s", env);
      else 
            printf("variable PATH is not defined");
      return 0;
}
