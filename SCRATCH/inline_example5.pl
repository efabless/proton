   use Inline CPP;

   my $farmer = new Farmer("Ingy", 42);
   my $slavedriver = 1;
   while($farmer->how_tired < 420) {
     $farmer->do_chores($slavedriver);
     $slavedriver <<= 1;
   }

   print "Wow! The farmer worked ", $farmer->how_long, " hours!\n";

   __END__
   __CPP__

   class Farmer {
   public:
     Farmer(char *name, int age);
     ~Farmer();

     int how_tired() { return tiredness; }
     int how_long() { return howlong; }
     void do_chores(int howlong);

   private:
     char *name;
     int age;
     int tiredness;
     int howlong;
   };

   Farmer::Farmer(char *name, int age) {
     this->name = strdup(name);
     this->age = age;
     tiredness = 0;
     howlong = 0;
   }

   Farmer::~Farmer() {
     free(name);
   }

   void Farmer::do_chores(int hl) {
     howlong += hl;
     tiredness += (age * hl);
   }
