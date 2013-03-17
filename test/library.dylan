module: dylan-user

define library slot-visitor-test
  use common-dylan;
  use slot-visitor;
  use io;
end library;

define module slot-visitor-test
  use common-dylan, exclude: { format-to-string };
  use slot-visitor;
  use streams;
  use standard-io;
  use format-out;
end module;
