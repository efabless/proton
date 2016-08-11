        #!/usr/local/bin/perl
        #
        # simple example taken from listing 1-1 (or 1-2) from OpenGL book
        #

        BEGIN{ unshift(@INC,"../blib");} # in case OpenGL is built but not installed
	BEGIN{ unshift(@INC,"../blib/lib");}
	BEGIN{ unshift(@INC,"../blib/arch");}
        use OpenGL;

        glpOpenWindow;
        glClearColor(0,0,1,1);
        glClear(GL_COLOR_BUFFER_BIT);
        glLoadIdentity;
        glOrtho(-1,1,-1,1,-1,1);

        glColor3f(1,0,0);
        glBegin(GL_POLYGON);
          glVertex2f(-0.5,-0.5);
          glVertex2f(-0.5, 0.5);
          glVertex2f( 0.5, 0.5);
          glVertex2f( 0.5,-0.5);
        glEnd();
        glFlush();

        print "Program 1-1 Simple, hit control-D to quit:\n\n";
        while(<>){;}
