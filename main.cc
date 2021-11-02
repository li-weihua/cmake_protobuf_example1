#include <iostream>

#include "proto/person.pb.h"
#include "proto/score.pb.h"
#include "proto/value.pb.h"

int main() {

  Person p;

  p.set_id(10);

  std::cout << p.id() << std::endl;

  return 0;
}
