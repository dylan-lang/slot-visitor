module: slot-visitor-test
synopsis: 
author: 
copyright: 

define class <unique-item> (<object>)
  slot unique-1 :: <string>;
  slot unique-2 :: <string>;
  slot collection :: <vector>;
end class;

define class <collection-item> (<object>) 
  slot coll-1 :: <string>;
  slot coll-2 :: <string>;
end class;

define collection-recursive slot-visitor visitor
  <unique-item>, unique-1, unique-2, collection;
  <collection-item>, coll-1, coll-2;
  <string> ;
end slot-visitor;

define function main (name :: <string>, arguments :: <vector>)
  let coll-item-1 = make(<collection-item>);
  let coll-item-2 = make(<collection-item>);
  coll-item-1.coll-1 := "collection 1-1";
  coll-item-1.coll-2 := "collection 1-2";
  coll-item-2.coll-1 := "collection 2-1";
  coll-item-2.coll-2 := "collection 2-2";

  let unique-item = make(<unique-item>);
  unique-item.unique-1 := "unique 1";
  unique-item.unique-2 := "unique 2";
  unique-item.collection := vector(coll-item-1, coll-item-2);
  
  visitor(unique-item,
      method (object, #key setter, visited) => (do-slots? :: <boolean>)
        format-out("%=\n", object);
        force-output(*standard-output*);
        #t
      end method);

  exit-application(0);
end function main;

main(application-name(), application-arguments());
