module: slot-visitor

// See README.txt for documentation.

define macro slot-visitor-definer
   { define collection-recursive slot-visitor ?:name ?classes end }
   => {
         define slot-visitor ?name ?classes end;

         define method ?name
            (col :: <collection>, action :: <function>, #rest keys,
             #key setter, visited :: <table> = make(limited(<table>, of: <boolean>)),
             #all-keys)
         => ()
            // Recurse into collection elements
            let pruned-keys = my-remove-property(keys, #[#"setter", #"visited"]);
            if (instance?(col, <mutable-collection>))
               for (o keyed-by i in col)
                  apply(?name, o, action, setter:, rcurry(my-element-setter, col, i),
                        visited:, visited, pruned-keys)
               end for
            else
               for (o keyed-by i in col)
                  apply(?name, o, action, setter:, #f, visited:, visited, pruned-keys)
               end for
            end if
         end method;

         define method ?name ## "-slots"
            (col :: <collection>, action :: <function>, #key, #all-keys)
         => ()
            // No slots in a collection
         end method
      }

   { define slot-visitor ?:name ?classes:* end }
   => {
         define generic ?name
            (o :: <object>, f :: <function>, #key, #all-keys)
         => ();
         
         define generic ?name ## "-slots"
            (o :: <object>, f :: <function>, #key, #all-keys)
         => ();

         class-visitors(?name; ?classes)
      }

classes:
   // If user specifies a visitor for <object>, ignore it; we'll be doing our
   // own regardless.
   { <object>, ?slots:* ; ... } => { ... }
   { ?class-name:name, ?slots:* ; ... } => { ?class-name, ?slots ; ... }
   { } => { }
end macro;


define macro class-visitors
   { class-visitors(?:name; ?class-name:name, ?slots; ?more:*) }
   => {
         define method ?name
            (object :: ?class-name, action :: <function>, #rest keys,
             #key setter, visited :: <table> = make(limited(<table>, of: <boolean>)),
             #all-keys)
         => ()
            unless (element(visited, object, default: #f))
               visited[object] := #t;
               let pruned-keys = my-remove-property(keys, #[#"setter", #"visited"]);
               let skip-slots? =
                     if (instance?(object, action.function-specializers.first))
                        ~ apply(action, object, setter:, setter, visited:, visited,
                                pruned-keys)
                     end if;
               unless (skip-slots?)
                  apply(?name ## "-slots", object, action, visited:, visited, pruned-keys)
               end unless;
            end unless;
         end method;

         define method ?name ## "-slots"
            (object :: ?class-name, action :: <function>, #next next-method,
             #rest keys, #key, #all-keys)
         => ()
            for (getter in getters-vector(?slots), setter in setters-vector(?slots))
               apply(?name, object.getter, action, setter:, setter & rcurry(setter, object),
                     keys)
            end for;
            next-method()  // Visit slots of superclasses
         end method;

         class-visitors(?name; ?more)
      }

   // When done with user-specified visitors, ensure there is also visitor on
   // <object> since the visitor is a generic method and might encounter one.
   // This won't visit any slots, but will perform the action if applicable.
   { class-visitors(?:name) }
   => { 
         define method ?name
            (object :: <object>, action :: <function>, #rest keys,
             #key setter, visited :: <table> = make(limited(<table>, of: <boolean>)),
             #all-keys)
         => ()
            unless (element(visited, object, default: #f))
               visited[object] := #t;
               let pruned-keys = my-remove-property(keys, #[#"setter", #"visited"]);
               if (instance?(object, action.function-specializers.first))
                  apply(action, object, setter:, setter, visited:, visited,
                        pruned-keys)
               end if;
            end unless;
         end method;

         define method ?name ## "-slots"
            (object :: <object>, action :: <function>, #next next-method,
             #rest keys, #key, #all-keys)
         => ()
            // Do nothing.
         end method;
      }

slots:
   { constant ?:name, ... } => { constant ?name, ... }
   { ?:name, ... } => { ?name, ... }
   { } => { }
end macro;


define macro setters-vector
   { setters-vector(?slots) } => { vector(?slots) }

slots:
   { constant ?:name, ... } => { #f, ... }
   { ?:name, ... } => { ?name ## "-setter", ... }
   { } => { }
end macro;


define macro getters-vector
   { getters-vector(?slots) } => { vector(?slots) }

slots:
   { constant ?:name, ... } => { ?name, ... }
   { ?:name, ... } => { ?name, ... }
   { } => { }
end macro;

// BUGFIX: This pass-through function works around issue #424.
define function my-element-setter (v, c :: <mutable-collection>, k)
   element-setter(v, c, k)
end function;

// BUGFIX: This function works around issue #443, which is that
// collections:plists:remove-property! does not work.
define function my-remove-property (key-value-pairs :: <sequence>, unwanted :: <collection>)
=> (new-keys :: <sequence>)
   let new-pairs = make(<stretchy-vector>);
   let old-pairs = as(<vector>, key-value-pairs);
   for (i from 0 below old-pairs.size by 2)
      let key = old-pairs[i];
      let val = old-pairs[i + 1];
      if (~member?(key, unwanted))
         add!(new-pairs, key);
         add!(new-pairs, val);
      end if;
   end for;
   new-pairs
end function;
